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

    # 13 Addressing modes:
    #  Absolute:
    #  Absolute Indirect:
    #  Absolute X-Indexed:
    #  Absolute Y-Indexed:
    #  Accumulator:
    #  Immediate:
    #  Implied: No date required, opcode [1 byte]
    #  Relative:
    #  Zero Page:
    #  Zero Page Indexed Indirect:
    #  Zero Page indirect Indexed:
    #  Zero Page X-Indexed:
    #  Zero Page Y-Indexed:
    @instruction_map = {
      # Nimonic AddressingMode : Description
      # CLC Implied: Clear carry flag
      0x18 => lambda {
        op_clear_flag(CpuFlag::FLAG_C)
        op_clock(2)
        op_step
      },

      # CLD Implied: Clear decimal flag
      0xD8 => lambda {
        op_clear_flag(CpuFlag::FLAG_D)
        op_clock(2)
        op_step
      },

      # CLI Implied: Clear interrupt disable flag
      0x58 => lambda {
        op_clear_flag(CpuFlag::FLAG_I)
        op_clock(2)
        op_step
      },

      # CLV Implied: Clear overflow flag
      0xB8 => lambda {
        op_clear_flag(CpuFlag::FLAG_V)
        op_clock(2)
        op_step
      },

      # SEC Implied: Set carry flag
      0x38 => lambda {
        op_set_flag(CpuFlag::FLAG_C)
        op_clock(2)
        op_step
      },

      # SED Implied: Set decimal flag
      0xF8 => lambda {
        op_set_flag(CpuFlag::FLAG_D)
        op_clock(2)
        op_step
      },

      # SEI Implied: Set interrupt disable flag
      0x78 => lambda {
        op_set_flag(CpuFlag::FLAG_I)
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
cpu.execute(0x58)
