require 'spec_helper'

describe FutureAgent do
  describe ".fork" do
    it "should return nil if the block gives nil" do
      fa = FutureAgent.fork { nil }
      fa.result.should be_nil
    end

    it "should return :foo if the block gives :foo" do
      fa = FutureAgent.fork { :foo }
      fa.result.should == :foo
    end

    it "should return a Time instance if the block gives Time.now" do
      fa = FutureAgent.fork { Time.now }
      fa.result.should be_a( Time )
    end

    it "should raise FutureAgent::ChildDied if the block raises an exception" do
      fa = FutureAgent.fork { raise }
      lambda { fa.result }.should raise_error( FutureAgent::ChildDied )
    end
  end
end

