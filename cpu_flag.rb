#!/usr/bin/ruby -Ku
# -*- coding: utf-8 -*-

require 'bit_field'

class CpuFlag < BitField
  FLAG_C = 0 # 0 bit, carry flag : C
  FLAG_Z = 1 # 1 bit, zero flag : Z
  FLAG_I = 2 # 2 bit, interrupt disable flag : I
  FLAG_D = 3 # 3 bit, decimal mode flag (ADC SBC works as BCD mode, Famicom's RP2A03 does not support this flag) : D
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
end
