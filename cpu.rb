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
    
    # reset stack pointer
    @reg_s.value = 0xFF

    @instruction_map = {
      # Nemonic : Description
      # CLC: Clear carry flag
      0x18 => lambda {
        op_clear_flag(CpuFlag::FLAG_C)
        op_clock(2)
        op_step
      },

      # CLD: Clear decimal flag
      0xD8 => lambda {
        op_clear_flag(CpuFlag::FLAG_D)
        op_clock(2)
        op_step
      },

      # CLI: Clear interrupt disable flag
      0x58 => lambda {
        op_clear_flag(CpuFlag::FLAG_I)
        op_clock(2)
        op_step
      },

      # CLV: Clear overflow flag
      0xB8 => lambda {
        op_clear_flag(CpuFlag::FLAG_V)
        op_clock(2)
        op_step
      },

      # DEX: Decrement X-register by one
      0xCA => lambda {
        @reg_x.value -= 1
        op_test(@reg_x.value)
        op_clock(2)
        op_step
      },

      # DEY: Decrement Y-register by one
      0x88 => lambda {
        @reg_y.value -= 1
        op_test(@reg_y.value)
        op_clock(2)
        op_step
      },

      # INX: Increment X-register by one
      0xE8 => lambda {
        @reg_x.value += 1
        op_test(@reg_x.value)
        op_clock(2)
        op_step
      },

      # INY: Increment Y-register by one
      0xC8 => lambda {
        @reg_y.value += 1
        op_test(@reg_y.value)
        op_clock(2)
        op_step
      },

      # LDA: Load accumulator from memory
      0xA9 => lambda {
        op_step
        op_lda(am_immediate)
        op_clock(2)
      },

      # LDA: Load accumulator from memory
      0xA5 => lambda {
        op_step
        op_lda(am_zero_page)
        op_clock(3)
      },

      # LDA: Load accumulator from memory
      0xB5 => lambda {
        op_step
        op_lda(am_zero_page_x_indexed)
        op_clock(4)
      },

      # LDA: Load accumulator from memory
      0xAD => lambda {
        op_step
        op_lda(am_absolute)
        op_clock(4)
      },

      # LDA: Load accumulator from memory
      0xBD => lambda {
        op_step
        op_lda(am_absolute_x_indexed)
        op_clock(4)
      },

      # LDA: Load accumulator from memory
      0xB9 => lambda {
        op_step
        op_lda(am_absolute_y_indexed)
        op_clock(4)
      },

      # LDA: Load accumulator from memory
      0xA1 => lambda {
        op_step
        op_lda(am_zero_page_indexed_indirect)
        op_clock(6)
      },

      # LDA: Load accumulator from memory
      0xB1 => lambda {
        op_step
        op_lda(am_zero_page_indexed_indirect)
        op_clock(5)
      },

      # NOP: No operation
      0xEA => lambda {
        op_clock(2)
        op_step
      },

      # SEC: Set carry flag
      0x38 => lambda {
        op_set_flag(CpuFlag::FLAG_C)
        op_clock(2)
        op_step
      },

      # SED: Set decimal flag
      0xF8 => lambda {
        op_set_flag(CpuFlag::FLAG_D)
        op_clock(2)
        op_step
      },

      # SEI: Set interrupt disable flag
      0x78 => lambda {
        op_set_flag(CpuFlag::FLAG_I)
        op_clock(2)
        op_step
      },

      # TAX: Transfer accumulator to X-register
      0xAA => lambda {
        @reg_x.value = @reg_a.value
        op_test(@reg_x.value)
        op_clock(2)
        op_step
      },

      # TAY: Transfer accumulator to Y-register
      0xA8 => lambda {
        @reg_y.value = @reg_a.value
        op_test(@reg_y.value)
        op_clock(2)
        op_step
      },

      # TSX: Transfer stack pointer to X-register
      0xBA => lambda {
        @reg_x.value = @reg_s.value
        op_test(@reg_x.value)
        op_clock(2)
        op_step
      },

      # TXA: Transfer X-register to accumulator
      0x8A => lambda {
        @reg_a.value = @reg_x.value
        op_test(@reg_a.value)
        op_clock(2)
        op_step
      },

      # TXS: Transfer X-register to stack pointer
      0x9A => lambda {
        @reg_s.value = @reg_x.value
        op_test(@reg_s.value)
        op_clock(2)
        op_step
      },

      # TYA: Transfer Y-register to accumulator
      0x98 => lambda {
        @reg_a.value = @reg_y.value
        op_test(@reg_a.value)
        op_clock(2)
        op_step
      },
    }
  end

  def op_read_byte(addr16)
    return @memory[addr16]
  end

  def op_read_word(addr16)
    return @memory[addr16 + 1] << 8 + @memory[addr16]
  end

  # Addressing mode #1 Implied
  # Addressing mode #2 Immediate
  def am_immediate
    addr16 = @reg_pc.value
    op_step
    return addr16
  end

  # Adressing Mode #3 Zero Page
  def am_zero_page
    addr8 = op_read_byte(@reg_pc.value)
    op_step
    return 0x0000 + addr8
  end

  # Addressing Mode #4 Zero Page X-Indexed
  def am_zero_page_x_indexed
    return am_zero_page + @reg_x.value
  end

  # Addressing Mode #5 Zero Page Y-Indexed
  def am_zero_page_y_indexed
    return am_zero_page + @reg_y.value
  end

  # Addressing Mode #6 Absolute
  def am_absolute
    addr16_low = op_read_byte(@reg_pc.value)
    op_step
    addr16_high = op_read_byte(@reg_pc.value)
    op_step
    return addr16_high << 8 + addr16_low
  end
  
  # Addressing Mode #7 Absolute X-Indexed
  def am_absolute_x_indexed
    return am_absolute + @reg_x.value
  end
  
  # Addressing Mode #8 Absolute Y-Indexed
  def am_absolute_y_indexed
    return am_absolute + @reg_y.value
  end
  
  # Addressing Mode #9 Zero Page Indexed indirect
  def am_zero_page_indexed_indirect
    return op_read_word(am_zero_page + @reg_x.value)
  end

  # Addressing Mode #10 Zero Page Indirect Indexed 
  def am_zero_page_indirect_indexed
    return op_read_word(am_zero_page) + @reg_y.value
  end

  def op_lda(addr16)
    @reg_a.value = op_read_byte(addr16)
    op_test(@reg_a.value)
  end

  def op_clock(n)
    @clock += n
  end

  def op_step(n = 1)
    @reg_pc.value += n
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
    if val8 >= 0x80
      @reg_p.set_flag(CpuFlag::FLAG_N)
    end
  end

  def set_memory(memory)
    @memory = memory
  end

  def execute
    while @reg_pc.value < @memory.size and @memory[@reg_pc.value] != 0x00
      puts "PC = #{@reg_pc.value}, FLAG = #{@reg_p.value}, CLK = #{@clock}"
      opcode = @memory[@reg_pc.value]
      @instruction_map[opcode].call
    end
  end
end


ADDR_MODE = 1..4

cpu = Cpu.new

# memory map
# 0x0000 - 0x00FF: Page Zero
# 0x0100 - 0x01FF: Page One (Stack)
# 0xFFFA - 0xFFFB: Non-maskabale interrupt vector
# 0xFFFC - 0xFFFD: Reset vector
# 0xFFFE - 0xFFFF: Maskable interrupt vector
memory = Array.new
memory.fill(0, 0x0000..0xFFFF)
code = [
        0x18, 0xD8, 0x58, 0xB8, 0x38, 0xF8, 0x78, 0xAA, 0xA8, 0xBA, 0x8A, 0x9A, 0x98, 0xCA, 0x88, 0xE8, 0xC8, 0xEA,
        0xA9, 0x00, 0xA5, 0x00, 0xB5, 0x00, 0xAD, 0x00, 0x00, 0xBD, 0x00, 0x00, 0xB9, 0x00, 0x00, 0xA1, 0x00, 0xB1, 0x00
       ]
memory[0..code.size] = code

cpu.set_memory(memory)
cpu.execute()
