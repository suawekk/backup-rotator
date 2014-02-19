module BackupRotator

    require 'socket'

    class JobServer
        CMD_MAX_LEN = 65535

        def initialize(num_jobs)
            # Setup pipes to read from children
            @jobs_count = num_jobs
            @job_pids = Array.new

            setup_sockets
            fork_children
            parent_loop

        end

        def setup_sockets
            @parent_sockets =  Array.new
            @children_sockets = Array.new

            (0...@jobs_count).each do
                parent,child = UNIXSocket.pair

                @parent_sockets << parent
                @children_sockets << child
            end
        end

        def fork_children
            (0...@jobs_count).each do |ind|

                pid = fork do
                    close_parent_socket(ind)

                    child_loop(ind)
                    # escape from loop
                    exit 0
                end

                close_child_socket(ind)

                @job_pids << pid
                puts "Currently spawned PIDs:"
                p @job_pids


            end
        end


        def read_child_socket(ind)
            @children_sockets[ind].recv(CMD_MAX_LEN)
        end

        def read_parent_socket(ind)
            @parent_sockets[ind].recv(CMD_MAX_LEN)
        end

        def write_child_socket(ind,data)
            @children_sockets[ind].send(data,0)
        end

        def write_parent_socket(ind,data)
            @parent_sockets[ind].send(data,0)
        end

        def close_parent_socket(ind)
            @parent_sockets[ind].close
        end

        def close_child_socket(ind)
            @children_sockets[ind].close
        end

        def close_readers

        end

        def enqueue_task(callback)

        end


        def process_child

        end

        def wait_for_status

        end

        def reap_children

        end

        def child_loop(ind)
            while txt = read_child_socket(ind)
                puts "child ##{ind} , pid ##{Process.pid} received \"#{txt}\" from parent"
                cmd_out = `#{txt}`
                write_child_socket(ind,"result is #{cmd_out},info is #{$?}")
            end
        end

        def parent_loop
            while true
                (0...@jobs_count).each do |i|
                    write_parent_socket(i,"dd if=/dev/random iflag=fullblock bs=16k count=1 2>/dev/null | sha256sum")
                    #resp = read_parent_socket(i)
                    #puts "Response from child #{i} = \"#{resp}\""
                end

                done_jobs = 0

                while done_jobs < @jobs_count
                    sockets = IO.select(@parent_sockets)

                    unless sockets[0].empty?
                        for sock in sockets[0]
                            child_no = @parent_sockets.index sock
                            puts "sock ##{child_no}: \"#{sock.recv(1000)}\""
                            done_jobs += 1
                        end
                    end
                end
            end

        end

        private :reap_children,:wait_for_status,:process_child,:close_readers,:fork_children,:setup_sockets

    end
end
