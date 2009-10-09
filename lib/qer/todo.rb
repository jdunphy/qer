module Qer
  class ToDo
    class << self
      attr_accessor :quiet
    end

    attr_accessor :queue
    attr_accessor :history

    def initialize(filename = File.expand_path("~/.qer-queue"))
      @filename  = filename
      @history_filename = "#{filename}-history"

      self.queue = Marshal.load(file) rescue []
      self.history = Marshal.load(history_file) rescue []
    end

    def file(mode = "r")
      File.new(@filename, mode)
    end

    def history_file(mode = "r")
      File.new(@history_filename, mode)
    end

    def size
      self.queue.size
    end

    def returning(thing)
      yield
      thing
    end

    def add(item)
      self.queue << [Time.now.to_s, item]
      write
      print "Adding: "+item
    end

    def remove(index)
      returning(item = self.queue.delete_at(index)) do
        self.history << [Time.now.to_s, item[0], item[1]]
        write_history
        write
        print "Removed #{item.last}"
      end
    end

    def clear
      self.queue = []
      write
      print "ToDo list cleared"
    end

    def pop
      remove(0)
    end

    def push(item)
      self.queue.unshift([Time.now.to_s, item])
      write
      print
    end

    def write
      Marshal.dump(self.queue, file("w+"))
    end

    def write_history
      Marshal.dump(self.history, history_file("w+"))
    end

    def width
      100
    end

    def title
      "> Stuff on the Hopper < ".center(width, '-')
    end

    def hl
      "".center(width, '-')
    end

    def tf(t)
      Time.time_ago(Time.parse(t))
    end

    def process_line(index, item)
      item.size == 2 ? process_queue_line(index,item) : process_history_line(index,item)
    end

    def process_queue_line(index, item)
      time, task = item
      left       = "(#{index}) #{task}"
      right      = tf(time).rjust(width - left.length)
      right.insert(0, left)
    end

    def process_history_line(index, item)
      end_time, time, task = item
      left      = "(#{index}) #{task}"
      right     = "#{tf(time)} | #{tf(end_time)}".rjust(width-left.length)
      right.insert(0, left)
    end

    def print(string = nil)
      dump self.queue, string
    end

    def print_history(string = nil)
      dump self.history, string, "Stuff Completed"
    end

    def dump(queue, string, label = title)
      out = []
      out << string if(string)
      out << label
      out << hl
      if(queue.size > 0)
        queue.each_index do |index|
          out << process_line(index, queue[index])
        end
      else
        out << "Nothing in this queue!"
      end
      out << hl
      puts out.join("\n") unless self.class.quiet
    end

    def command(args)
      case(args.shift)
      when /^a(dd)?/     : self.add(args.join(" "))     # qer add Some task 1
      when /^r(emove)?/  : self.remove(args.shift.to_i) # qer remove 0
      when /^pu(sh)?/    : self.push(args.join(" "))    # qer push Some task 2
      when /^po(p)?/     : self.pop                     # qer pop
      when /^clear/      : self.clear                   # qer clear
      when /^h(istory)?/  : self.print_history           # qer history
      when /.*help/      : self.help                    # qer help
      else self.print                                 # qer
      end
    end

    def help
      string = <<-EOF
#{hl}
Help for Qer, the friendly easy todo list queueing system.
#{hl}
Commands:
  print - Prints out the task list
    `qer`
  a(dd) - Adds a task to the end of the list
    `qer add Stuff to do`
  r(emove) - Remove the given task number from the list
    `qer remove 2`
  pu(sh) - Push a task onto the top of the list
    `qer push Another boring thing`
  po(p) - Pops the top item off the list
    `qer pop`
  clear - Clears the entire list
    `qer clear`
  history - displays list of completed tasks
    `qer history`
  help - Prints this message
    `qer help`
#{hl}
      EOF
      puts string unless self.class.quiet
    end
  end
end
