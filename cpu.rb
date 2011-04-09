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

      # TAX Implied: Transfer accumulator to X-register
      0xAA => lambda {
        val8 = @reg_a.value
        @reg_x.value = val8
        op_test(val8)
        op_clock(2)
        op_step
      },

      # TAY Implied: Transfer accumulator to Y-register
      0xA8 => lambda {
        val8 = @reg_a.value
        @reg_y.value = val8
        op_test(val8)
        op_clock(2)
        op_step
      },

      # TSX Implied: Transfer stack pointer to X-register
      0xBA => lambda {
        val8 = @reg_s.value
        @reg_x.value = val8
        op_test(val8)
        op_clock(2)
        op_step
      },

      # TXA Implied: Transfer X-register to accumulator
      0x8A => lambda {
        val8 = @reg_x.value
        @reg_a.value = val8
        op_test(val8)
        op_clock(2)
        op_step
      },

      # TXS Implied: Transfer X-register to stack pointer
      0x9A => lambda {
        val8 = @reg_x.value
        @reg_s.value = val8
        op_test(val8)
        op_clock(2)
        op_step
      },

      # TYA Implied: Transfer Y-register to accumulator
      0x98 => lambda {
        val8 = @reg_y.value
        @reg_a.value = val8
        op_test(val8)
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

  def op_test(val8)
    raise if val8 < 0 or val8 > 255
    @reg_p.clear_flag(CpuFlag::FLAG_N)
    @reg_p.clear_flag(CpuFlag::FLAG_Z)
    if val8 == 0
      @reg_p.set_flag(CpuFlag::FLAG_Z)
    end
    if val8 > 127
      @reg_p.set_flag(CpuFlag::FLAG_N)
    end
  end

  def execute(memory)
    while @reg_pc.value < memory.size
      puts "PC = #{@reg_pc.value}, FLAG = #{@reg_p.value}, CLK = #{@clock}"
      opcode = memory[@reg_pc.value]
      @instruction_map[opcode].call
    end
  end
end


ADDR_MODE = 1..4

cpu = Cpu.new

memory = [0x18, 0xD8, 0x58, 0xB8, 0x38, 0xF8, 0x78, 0xAA, 0xA8, 0xBA, 0x8A, 0x9A, 0x98]
cpu.execute(memory)
