#!/usr/bin/ruby -Ku
# -*- coding: utf-8 -*-

BYTE = 0..7
WORD = 0..15

class BitField
  def initialize(size)
    raise if !size.is_a?(Integer)
    raise if size == 0
    @size = size
    @mask = (0x1 << size) - 1
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


cpu_flag = BitField.new(8)
instr = BitField.new(8)
#addr = BitField.new(16)

cpu_flag.value = 0b10101010
instr.value =0b11001100

FLAG_C = 0
FLAG_Z = 1
FLAG_I = 2
FLAG_D = 3
FLAG_B = 4
FLAG_R = 5
FLAG_V = 6
FLAG_N = 7

puts sprintf("%01b", cpu_flag[FLAG_C])
puts sprintf("%01b", cpu_flag[FLAG_Z])

ADDR_MODE = 1..4
puts sprintf("%04b", instr[ADDR_MODE])

#puts sprintf("%b", cpu_flag[8])
