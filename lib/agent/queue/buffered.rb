require "agent/queue"

module Agent
  class Queue
    class Buffered < Queue
      class InvalidQueueSize < Exception; end

      attr_reader :size, :max

      def initialize(max=1)
        raise InvalidQueueSize, "queue size must be at least 1" unless max >= 1
        super()
        @max = max
      end

      def buffered?;   true; end
      def unbuffered?; false;  end

      def push?; @max > @size; end
      def pop?;  @size > 0;    end

    protected

      def reset_custom_state
        @size = @queue.size
      end

      def process
        return if (pops.empty? && !push?) || (pushes.empty? && !pop?)

        operation = operations.first

        loop do
          if operation.is_a?(Push)
            if push?
              operation.receive do |obj|
                @size += 1
                queue.push(obj)
              end
              operations.delete(operation)
              pushes.delete(operation)
            elsif pop? && operation = pops[0]
              next
            else
              break
            end
          else # Pop
            if pop?
              operation.send do
                @size -= 1
                queue.shift
              end
              operations.delete(operation)
              pops.delete(operation)
            elsif push? && operation = pushes[0]
              next
            else
              break
            end
          end

          case operations[0]
          when Push
            if push?
              operation = operations[0]
            elsif pop? && operation = pops[0]
              next
            else
              break
            end
          when Pop
            if pop?
              operation = operations[0]
            elsif push? && operation = pushes[0]
              next
            else
              break
            end
          else
            break
          end
        end
      end

    end
  end
end
