require "asana"
require "terminal-table"

TOKEN = ENV["ASANA_TOKEN"]
raise "no ENV var ASANA_TOKEN" if TOKEN == nil
TEAM = ENV["TEAM_ID"]
raise "no ENV var TEAM_ID" if TEAM == nil

def get_tasks_from_api
  client = Asana::Client.new do |c|
    c.default_headers "asana-enable" => "string_ids"
    c.authentication :access_token, TOKEN
  end
  
  week_ago = (Time.now - 7 * 24 * 60 * 60).strftime('%Y-%m-%dT%H:%M:%S.%L%z')
  
  leadership_projects = client.projects.find_all(team: TEAM)
  
  all_tasks = {
    late: {},
    upcoming: {},
    completed: {},
    unassigned: {}
  }
  leadership_projects.each do |p|
    tasks_for_project = client.tasks.find_all(
      project: p.gid,
      completed_since: week_ago,
      options: {fields: ["due_on", "name", "projects.name", "assignee.name", "completed_at"]}
    ).each do |task|
      if task.completed_at != nil  
        completed_date = Date.parse(task.completed_at) 
      end
      if completed_date
        all_tasks[:completed][p.name] ||= []
        all_tasks[:completed][p.name] << task
      else
        if task.due_on != nil   
          due_date = Date.parse(task.due_on) 
        end
        if due_date
          if due_date < Time.now.to_date
            all_tasks[:late][p.name] ||= []
            all_tasks[:late][p.name] << task
          else
            all_tasks[:upcoming][p.name] ||= []
            all_tasks[:upcoming][p.name] << task
          end
        else
          all_tasks[:unassigned][p.name] ||= []
          all_tasks[:unassigned][p.name] << task
        end
      end
    end
  end
  return all_tasks
end

def add_tasks_to_row(label, tasks)
  rows = []
  rows << [label]
  if tasks.length > 0
    tasks.each_pair do |k, v|
      v.each do |task|
        if task.name != "" && task.due_on != nil
          rows << ["", k, task.name.scan(/.{1,40}/).join("\n"), task.due_on, task.assignee["name"]]
        end
      end
    end
  else
    rows << ["No tasks"]
  end
  rows
end

tasks = get_tasks_from_api

rows = []

rows += add_tasks_to_row("late", tasks[:late])
rows += add_tasks_to_row("upcoming", tasks[:upcoming])
rows += add_tasks_to_row("unassigned", tasks[:unassigned])
rows += add_tasks_to_row("completed", tasks[:completed])


table = Terminal::Table.new( :rows => rows)
puts table