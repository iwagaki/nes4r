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
      },

      # CLD: Clear decimal flag
      0xD8 => lambda {
        op_clear_flag(CpuFlag::FLAG_D)
        op_clock(2)
      },

      # CLI: Clear interrupt disable flag
      0x58 => lambda {
        op_clear_flag(CpuFlag::FLAG_I)
        op_clock(2)
      },

      # CLV: Clear overflow flag
      0xB8 => lambda {
        op_clear_flag(CpuFlag::FLAG_V)
        op_clock(2)
      },

      # DEX: Decrement X-register by one
      0xCA => lambda {
        @reg_x.value -= 1
        op_test(@reg_x.value)
        op_clock(2)
      },

      # DEY: Decrement Y-register by one
      0x88 => lambda {
        @reg_y.value -= 1
        op_test(@reg_y.value)
        op_clock(2)
      },

      # INX: Increment X-register by one
      0xE8 => lambda {
        @reg_x.value += 1
        op_test(@reg_x.value)
        op_clock(2)
      },

      # INY: Increment Y-register by one
      0xC8 => lambda {
        @reg_y.value += 1
        op_test(@reg_y.value)
        op_clock(2)
      },

      # LDA: Load accumulator from memory
      0xA9 => lambda {
        op_lda(get_addr_immediate)
        op_clock(2)
      },

      0xA5 => lambda {
        op_lda(get_addr_zero_page)
        op_clock(3)
      },

      0xB5 => lambda {
        op_lda(get_addr_zero_page_x_indexed)
        op_clock(4)
      },

      0xAD => lambda {
        op_lda(get_addr_absolute)
        op_clock(4)
      },

      0xBD => lambda {
        op_lda(get_addr_absolute_x_indexed)
        op_clock(4)
      },

      0xB9 => lambda {
        op_lda(get_addr_absolute_y_indexed)
        op_clock(4)
      },

      0xA1 => lambda {
        op_lda(get_addr_zero_page_indexed_indirect)
        op_clock(6)
      },

      0xB1 => lambda {
        op_lda(get_addr_zero_page_indirect_indexed)
        op_clock(5)
      },

      # NOP: No operation
      0xEA => lambda {
        op_clock(2)
      },

      # PHA: Push accumulator on stack
      0x48 => lambda {
        op_push(@reg_a.value)
        op_clock(3)
      },

      # PHP: Push status flags on stack
      0x08 => lambda {
        op_push(@reg_p.value)
        op_clock(3)
      },

      # PLA: Pull accumulator from stack
      0x68 => lambda {
        @reg_a.value = op_pop
        op_test(@reg_a.value)
        op_clock(4)
      },

      # PLP: Pull status flags from stack
      0x28 => lambda {
        @reg_p.value = op_pop
        op_clock(4)
      },

      # SEC: Set carry flag
      0x38 => lambda {
        op_set_flag(CpuFlag::FLAG_C)
        op_clock(2)
      },

      # SED: Set decimal flag
      0xF8 => lambda {
        op_set_flag(CpuFlag::FLAG_D)
        op_clock(2)
      },

      # SEI: Set interrupt disable flag
      0x78 => lambda {
        op_set_flag(CpuFlag::FLAG_I)
        op_clock(2)
      },

      # TAX: Transfer accumulator to X-register
      0xAA => lambda {
        @reg_x.value = @reg_a.value
        op_test(@reg_x.value)
        op_clock(2)
      },

      # TAY: Transfer accumulator to Y-register
      0xA8 => lambda {
        @reg_y.value = @reg_a.value
        op_test(@reg_y.value)
        op_clock(2)
      },

      # TSX: Transfer stack pointer to X-register
      0xBA => lambda {
        @reg_x.value = @reg_s.value
        op_test(@reg_x.value)
        op_clock(2)
      },

      # TXA: Transfer X-register to accumulator
      0x8A => lambda {
        @reg_a.value = @reg_x.value
        op_test(@reg_a.value)
        op_clock(2)
      },

      # TXS: Transfer X-register to stack pointer
      0x9A => lambda {
        @reg_s.value = @reg_x.value
        op_test(@reg_s.value)
        op_clock(2)
      },

      # TYA: Transfer Y-register to accumulator
      0x98 => lambda {
        @reg_a.value = @reg_y.value
        op_test(@reg_a.value)
        op_clock(2)
      },
    }
  end

  def op_read_byte(addr16)
    return @memory[addr16]
  end

  def op_read_word(addr16)
    return (@memory[addr16 + 1] << 8) + @memory[addr16]
  end

  def op_write_byte(addr16, val8)
    @memory[addr16] = val8
  end

  def op_push(val8)
    @memory[get_addr_stack] = val8
    @reg_s.value -= 1
  end

  def op_pop
    @reg_s.value += 1
    return @memory[get_addr_stack]
  end

  def get_addr_stack
    return 0x0100 + @reg_s.value
  end

  # 13 addressing modes (including "Implied")
  def get_addr_immediate
    addr16 = @reg_pc.value
    op_step
    return addr16
  end

  def get_addr_zero_page
    addr8 = op_read_byte(@reg_pc.value)
    op_step
    return 0x0000 + addr8
  end

  def get_addr_zero_page_x_indexed
    return get_addr_zero_page + @reg_x.value
  end

  def get_addr_zero_page_y_indexed
    return get_addr_zero_page + @reg_y.value
  end

  def get_addr_absolute
    addr16_low = op_read_byte(@reg_pc.value)
    op_step
    addr16_high = op_read_byte(@reg_pc.value)
    op_step
    return (addr16_high << 8) + addr16_low
  end
  
  def get_addr_absolute_x_indexed
    return get_addr_absolute + @reg_x.value
  end
  
  def get_addr_absolute_y_indexed
    return get_addr_absolute + @reg_y.value
  end
  
  def get_addr_zero_page_indexed_indirect
    return op_read_word(get_addr_zero_page + @reg_x.value)
  end

  def get_addr_zero_page_indirect_indexed
    return op_read_word(get_addr_zero_page) + @reg_y.value
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
    while @reg_pc.value < @memory.size
      puts sprintf("PC:%04X CLK:%04d A:%02X X:%02X Y:%02X S:%02X %s",
                   @reg_pc.value, @clock, @reg_a.value, @reg_x.value, @reg_y.value, @reg_s.value, @reg_p.to_s)
      opcode = op_read_byte(get_addr_immediate)
      if opcode == 0
        break
      end
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
        0xA9, 0x00, 0xA5, 0x00, 0xB5, 0x00, 0xAD, 0x00, 0x00, 0xBD, 0x00, 0x00, 0xB9, 0x00, 0x00, 0xA1, 0x00, 0xB1, 0x00,
        0x48, 0x08, 0x28, 0x68
       ]
memory[0..code.size] = code

cpu.set_memory(memory)
cpu.execute()

