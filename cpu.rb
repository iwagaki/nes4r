#!/usr/bin/ruby -Ku
# -*- coding: utf-8 -*-

require 'bit_field'
require 'cpu_flag'

BYTE = 0..7 # 1 byte = 8 bits
WORD = 0..15 # 1 word = 16 bits

class Cpu
  def initialize()
    @reg_pc = BitField.new(16) # 16 bits, program counter: PC
    @reg_a = BitField.new(8) # 8 bits, accumulator: A
    @reg_x = BitField.new(8) # 8 bits, X-index: X
    @reg_y = BitField.new(8) # 8 bits, Y-index: Y
    @reg_s = BitField.new(8) # 8 bits, stack pointer: S
    @reg_p = CpuFlag.new # 8 bits, status flags: P
    @clock = 0

    @instruction_map = {
      # CLC: clear carry flag
      0x18 => lambda {
        op_clear_flag(CpuFlag::FLAG_C)
        op_clock(2)
        op_step
      },
    }
  end

  def op_clock(n)
    @clock += n
  end

  def op_step(n = 1)
    @reg_pc.value = @reg_pc.value + n
  end

  def op_set_flag(index)
    @reg_p.set_flag(index)
  end

  def op_clear_flag(index)
    @reg_p.clear_flag(index)
  end

  def execute(code)
    p @instruction_map[code].call
  end

end


ADDR_MODE = 1..4

cpu = Cpu.new
cpu.execute(0x18)
