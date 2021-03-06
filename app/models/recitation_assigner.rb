class RecitationAssigner
  # The registration information for each student to be assigned to a section.
  attr_accessor :registrations
  # The recitation sections that should be considered in the assignment process.
  attr_accessor :sections
  # The maximum number of students in a recitation section.
  attr_accessor :section_capacity

  # Creates a new recitation assigner for the given course.
  def initialize(course)
    self.registrations = course.registrations.
        includes(:user, :recitation_conflicts).reject { |r| r.user.admin? }
    self.sections = course.recitation_sections
    self.section_capacity = course.section_size
  end

  # Creates a RecitationPartition assigning students to recitation sections.
  #
  # @return [RecitationPartition] the final proposed partition
  def partition!
    graph = assignment_graph
    matching = best_matching! graph
    registration_map = graph[:registration_map]
    section_map = graph[:section_map]

    section_members = {}
    matching.each do |source_vertex, sink_vertex|
      registration = registration_map[source_vertex]
      section = section_map[sink_vertex]
      section_members[section] ||= []
      section_members[section] << registration
    end

    course = registrations.first.course
    partition = RecitationPartition.create! course: course,
        section_size: section_capacity,
        section_count: section_members.length

    partition.create_assignments section_members
    partition
  end

  # Builds a bipartite graph for matching students to recitation sections.
  #
  # @return [Hash] a bipartite graph connecting a source vertex to registration
  #   vertices, section seat vertices to a sink vertex, and registration
  #   vertices to the seat vertices of sections that the students can attend
  def assignment_graph
    next_vertex = 2
    registration_map = {}
    registration_vertex = {}

    # One vertex per registration.
    registrations.each do |registration|
      registration_map[next_vertex] = registration
      registration_vertex[registration] = next_vertex
      next_vertex += 1
    end

    # One vertex per section seat. Each section has section_capacity seats.
    section_map = {}
    section_vertices = {}
    sections.each do |section|
      seat_vertices = []
      section_vertices[section] = seat_vertices
      0.upto section_capacity - 1 do
        section_map[next_vertex] = section
        seat_vertices << next_vertex
        next_vertex += 1
      end
    end

    source = 0
    sink = 1
    edges = { source => {}, sink => {} }

    # Edges from source to registrations.
    registration_map.each do |vertex, _|
      edges[source][vertex] = 0
    end
    # Edges from seats to sink.
    section_map.each do |vertex, _|
      edges[vertex] = { sink => 0 }
    end
    # Edges from registrations to seats.
    possible_assignments.each do |registration, possible_sections|
      reg_vertex = registration_vertex[registration]
      edges[reg_vertex] = {}
      possible_sections.each do |section|
        section_vertices[section].each do |seat_vertex|
          edges[reg_vertex][seat_vertex] = 0
        end
      end
    end

    {
      source: 0,
      sink: 1,
      section_map: section_map,
      registration_map: registration_map,
      edges: edges,
      vertex_count: next_vertex
    }
  end

  # Computes the sections that students can be assigned to.
  #
  # @return [Hash<Registration, Array<Section>>] maps students' registrations
  #   for the course to recitation sections that they can attend
  def possible_assignments
    return_value = {}
    registrations.each do |registration|
      return_value[registration] = available_sections registration
    end
    return_value
  end

  # Computes which of the given recitation sections a student can attend.
  #
  # @param [Registration] registration registration information for the student
  #     in question
  # @return [Array<Section>] the sections that a student can attend
  def available_sections(registration)
    blocked_times = Set.new(registration.recitation_conflicts.reject { |c|
      # This filter cleans up data entered by less bright students.
      # * some students enter the registrar-assigned recitation time as a
      #   conflict
      # * some students try to block off time for non-classes by entering e.g.
      #   "sleep"; these entries are silently ignored
      #
      # TODO(pwnall): move this log into the registration form validation, and
      #               tell students when their data entry is ignored
      c.class_name == registration.course.number ||
          !(/\A(\w+)\.(\w+)\Z/.match(c.class_name))
    }.map(&:time_slot))

    sections.reject do |section|
      section.time_slots.any? { |ts| blocked_times.include? ts }
    end
  end

  # Finds a maximal matching in a bipartite graph. Mutates the graph.
  #
  # @param [Hash] graph a graph produced by {assignment_graph}
  # @return [Hash<Number, Number>] a maximal matching in the graph; the keys
  #   are the vertices connected to the source, the values are the vertices
  #   connected to the sink
  def best_matching!(graph)
    loop do
      path = augmenting_path graph
      break unless path
      augment_flow_graph! graph, path
    end
    matching graph
  end

  # Finds an augmenting path in a matching graph.
  #
  # @param [Hash] graph a graph produced by {assignment_graph}
  # @return [Array<Array<Number>>] a path from the source vertex to the sink
  #    vertex, as an array of edge arrays; example: [[0, 3], [3, 5], [5, 1]]
  def augmenting_path(graph)
    # TODO(costan): replace this with Bellman-Ford to support min-cost matching.

    source = graph[:source]
    sink = graph[:sink]
    edges = graph[:edges]

    # Breadth-first search.
    parents = []
    parents[source] = true
    queue = [source]
    until queue.empty?
      current_vertex = queue.shift
      break if current_vertex == sink
      (edges[current_vertex] || {}).each do |new_vertex, edge|
        next if parents[new_vertex]
        parents[new_vertex] = current_vertex
        queue << new_vertex
      end
    end
    return nil unless parents[sink]

    # Reconstruct the path.
    path = []
    current_vertex = sink
    until current_vertex == source
      path << [parents[current_vertex], current_vertex]
      current_vertex = parents[current_vertex]
    end
    path.reverse!
  end

  # Augments a flow graph along a path.
  #
  # @param [Hash] graph a graph produced by {assignment_graph}
  # @param [Array<Array<Number>>] an augmenting path produced by
  #   {augmenting_path}
  def augment_flow_graph!(graph, path)
    # Turn normal edges into residual edges and viceversa.
    edges = graph[:edges]
    path.each do |u, v|
      edges[v][u] = -edges[u][v]
      edges[u].delete v
    end
  end

  # The matching encoded in a matching graph.
  #
  # @param [Hash] graph a graph produced by {assignment_graph}
  # @return [Hash<Number, Number>] the matching encoded in the graph; the keys
  #   are the vertices connected to the source, the values are the vertices
  #   connected to the sink
  def matching(graph, source = :source, sink = :sink)
    source = graph[:source]
    sink = graph[:sink]
    edges = graph[:edges]

    matches = {}
    # The network of residual edges contains the matching.
    edges[sink].each do |right_vertex, _|
      left_vertex = edges[right_vertex].first[0]
      matches[left_vertex] = right_vertex
    end
    matches
  end
end
