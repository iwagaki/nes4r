#!/usr/bin/ruby -Ku
# -*- coding: utf-8 -*-

require 'bit_field'

class CpuFlag < BitField
  FLAG_C = 0 # 0 bit, carry flag : C
  FLAG_Z = 1 # 1 bit, zero flag : Z
  FLAG_I = 2 # 2 bit, interrupt disable flag : I
  FLAG_D = 3 # 3 bit, decimal mode flag (BCD mode for ADC and SBC) : D
             #        Famicom's RP2A03 does not support this flag, though it can be set/cleared
  FLAG_B = 4 # 4 bit, break flag : B
  FLAG_R = 5 # 5 bit, reserved (shoud be 1) : R
  FLAG_V = 6 # 6 bit, overflow flag (arithmetic overflow) : V
  FLAG_N = 7 # 7 bit, sign flag: N

  def initialize
    super(8)
    reset
  end

  def reset
    self.value = 0

    # R is a reserved flag, and should be 1
    self[FLAG_R] = 1
  end

  def set_flag(index)
    self[index] = 1
  end

  def clear_flag(index)
    self[index] = 0
  end

  def get_flag(index)
    return self[index]
  end

  def to_s
    str = (self[FLAG_N] == 0 ? '_' : 'N')
    str << (self[FLAG_V] == 0 ? '_' : 'V')
    str << (self[FLAG_R] == 0 ? '_' : 'R')
    str << (self[FLAG_B] == 0 ? '_' : 'B')
    str << (self[FLAG_D] == 0 ? '_' : 'D')
    str << (self[FLAG_I] == 0 ? '_' : 'I')
    str << (self[FLAG_Z] == 0 ? '_' : 'Z')
    str << (self[FLAG_C] == 0 ? '_' : 'C')
    return str
  end
end
