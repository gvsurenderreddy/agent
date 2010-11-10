require "helper"

describe "sieve of Eratosthenes" do

  # http://golang.org/doc/go_tutorial.html#tmp_353

  it "should work using Channel primitives" do

    # send the sequence 2,3,4, ... to returned channel
    def generate
      ch = Go::Channel.new(name: 'generator', type: Integer)

      go do
        i = 1
        loop { ch << i+= 1 }
      end

      return ch
    end

    # filter out input values divisible by *prime*, send rest to returned channel
    def filter(in_channel, prime)
      out = Go::Channel.new(name: "filter-#{prime}", type: Integer)

      go do
        loop do
          i = in_channel.receive
          out << i if (i % prime) != 0
        end
      end

      return out
    end

    def sieve
      out = Go::Channel.new(name: 'sieve', type: Integer)

      go do
        ch = generate
        loop do
          prime = ch.receive
          out << prime
          ch = filter(ch, prime)
        end
      end

      return out
    end

    # run the sieve
    n = 20
    nth = false

    primes = sieve
    result = []

    if nth
      n.times { primes.receive }
      puts primes.receive
    else
      loop do
        p = primes.receive

        if p <= n
          result << p
        else
          break
        end
      end
    end

    result.should == [2,3,5,7,11,13,17,19]
  end

  it "should work with Ruby blocks" do

    # send the sequence 2,3,4, ... to returned channel
    generate = Proc.new do
      ch = Go::Channel.new(name: 'generator-block', type: Integer)

      go do
        i = 1
        loop { ch << i+= 1 }
      end

      ch
    end

    # filter out input values divisible by *prime*, send rest to returned channel
    filtr = Proc.new do |in_channel, prime|
      out = Go::Channel.new(name: "filter-#{prime}-block", type: Integer)

      go do
        loop do
          i = in_channel.receive
          out << i if (i % prime) != 0
        end
      end

      out
    end

    sieve = -> do
      out = Go::Channel.new(name: 'sieve-block', type: Integer)

      go do
        ch = generate.call

        loop do
          prime = ch.receive
          out << prime
          ch = filtr.call(ch, prime)
        end
      end

      out
    end

    # run the sieve
    n = 20
    nth = false

    primes = sieve.call
    result = []

    if nth
      n.times { primes.receive }
      puts primes.receive
    else
      loop do
        p = primes.receive

        if p <= n
          result << p
        else
          break
        end
      end
    end

    result.should == [2,3,5,7,11,13,17,19]
  end
end