#!/usr/bin/ruby -Ku
# -*- coding: utf-8 -*-

class BitField
  def initialize(size)
    raise if !size.is_a?(Integer)
    raise if size == 0
    @size = size
    @mask = (0x1 << size) - 1
    @value = 0
  end

  def value
    return @value
  end

  def value=(value)
    @value = value & @mask
  end

  def [](range)
    if range.is_a?(Integer)
      raise if range >= @size
      return @value[range]
    else
      raise if range.begin < 0
      raise if range.end >= @size
      return (@value & ((0x1 << (range.end + 1)) - 1)) >> range.begin
    end
  end

  def []=(range, value)
    @value = value
  end
end
