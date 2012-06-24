#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require './bit_field'
require './cpu_flag'

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
      # ADC: add with carry
      0x6D => lambda {
        op_adc(get_addr_absolute)
        op_clock(4)
      },

      0x65 => lambda {
        op_adc(get_addr_zero_page)
        op_clock(3)
      },

      0x69 => lambda {
        op_adc(get_addr_immediate)
        op_clock(2)
      },

      0x7D => lambda {
        op_adc(get_addr_absolute_x_indexed)
        op_clock(4) # +1
      },

      0x79 => lambda {
        op_adc(get_addr_absolute_y_indexed)
        op_clock(4) # +1
      },

      0x61 => lambda {
        op_adc(get_addr_zero_page_indexed_indirect)
        op_clock(6)
      },

      0x71 => lambda {
        op_adc(get_addr_zero_page_indirect_indexed)
        op_clock(5) # +1
      },

      0x75 => lambda {
        op_adc(get_addr_zero_page_x_indexed)
        op_clock(4)
      },

      # AND: and
      0x2D => lambda {
        op_and(get_addr_absolute)
        op_clock(4)
      },

      0x25 => lambda {
        op_and(get_addr_zero_page)
        op_clock(3)
      },

      0x29 => lambda {
        op_and(get_addr_immediate)
        op_clock(2)
      },

      0x3D => lambda {
        op_and(get_addr_absolute_x_indexed)
        op_clock(4) # +1
      },

      0x39 => lambda {
        op_and(get_addr_absolute_y_indexed)
        op_clock(4) # +1
      },

      0x21 => lambda {
        op_and(get_addr_zero_page_indexed_indirect)
        op_clock(6)
      },

      0x31 => lambda {
        op_and(get_addr_zero_page_indirect_indexed)
        op_clock(5) # +1
      },

      0x35 => lambda {
        op_and(get_addr_zero_page_x_indexed)
        op_clock(4)
      },

      # ASL: arithmetic shift left
      0x0A => lambda {
        @reg_a.value = op_asl_val8(@reg_a.value)
        op_clock(2)
      },

      0x0E => lambda {
        op_asl(get_addr_absolute)
        op_clock(6)
      },

      0x06 => lambda {
        op_asl(get_addr_zero_page)
        op_clock(5)
      },

      0x1E => lambda {
        op_asl(get_addr_absolute_x_indexed)
        op_clock(7)
      },

      0x16 => lambda {
        op_asl(get_addr_zero_page_x_indexed)
        op_clock(6)
      },

      # BCC: branch on carry clear
      0x90 => lambda {
        op_branch(!@reg_p.get_flag(CpuFlag::FLAG_C))
        op_clock(2) # TODO
      },

      # BCS: branch on carry set
      0xB0 => lambda {
        op_branch(@reg_p.get_flag(CpuFlag::FLAG_C))
        op_clock(2) # TODO
      },

      # BEQ: branch if equal to zero
      0xF0 => lambda {
        op_branch(@reg_p.get_flag(CpuFlag::FLAG_Z))
        op_clock(2) # TODO
      },

      # BIT: bit test (compare memory bits with A)
      # TODO

      # BMI: branch on minus
      0x30 => lambda {
        op_branch(@reg_p.get_flag(CpuFlag::FLAG_N))
        op_clock(2) # TODO
      },

      # BNE: branch if not equal to zero
      0xD0 => lambda {
        op_branch(!@reg_p.get_flag(CpuFlag::FLAG_Z))
        op_clock(2) # TODO
      },

      # BPL: branch on plus
      0x10 => lambda {
        op_branch(!@reg_p.get_flag(CpuFlag::FLAG_N))
        op_clock(2) # TODO
      },

      # BRK: break
      # TODO

      # BVC: branch on overflow clear
      0x50 => lambda {
        op_branch(!@reg_p.get_flag(CpuFlag::FLAG_V))
        op_clock(2) # TODO
      },

      # BVS: branch on overflow set
      0x70 => lambda {
        op_branch(@reg_p.get_flag(CpuFlag::FLAG_N))
        op_clock(2) # TODO
      },

      # CLC: clear carry
      0x18 => lambda {
        op_clear_flag(CpuFlag::FLAG_C)
        op_clock(2)
      },

      # CLD: clear decimal flag
      0xD8 => lambda {
        op_clear_flag(CpuFlag::FLAG_D)
        op_clock(2)
      },

      # CLI: clear interrupt mask
      0x58 => lambda {
        op_clear_flag(CpuFlag::FLAG_I)
        op_clock(2)
      },

      # CLV: clear overflow flag
      0xB8 => lambda {
        op_clear_flag(CpuFlag::FLAG_V)
        op_clock(2)
      },

      # CMP: compare to A
      # CPX: compare to X
      # CPY: compare to Y
      # DEC: decrement

      # DEX: decrement X
      0xCA => lambda {
        @reg_x.value -= 1
        op_test(@reg_x.value)
        op_clock(2)
      },

      # DEY: decrement Y
      0x88 => lambda {
        @reg_y.value -= 1
        op_test(@reg_y.value)
        op_clock(2)
      },

      # EOR: exclusive or
      # INC: increment

      # INX: increment X
      0xE8 => lambda {
        @reg_x.value += 1
        op_test(@reg_x.value)
        op_clock(2)
      },

      # INY: increment Y
      0xC8 => lambda {
        @reg_y.value += 1
        op_test(@reg_y.value)
        op_clock(2)
      },

      # JMP: jump
      # JSR: jump to subroutine

      # LDA: load A
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

      # LDX: load X
      0xA2 => lambda {
        op_ldx(get_addr_immediate)
        op_clock(2)
      },

      0xA6 => lambda {
        op_ldx(get_addr_zero_page)
        op_clock(3)
      },

      0xB6 => lambda {
        op_ldx(get_addr_zero_page_y_indexed)
        op_clock(4)
      },

      0xAE => lambda {
        op_ldx(get_addr_absolute)
        op_clock(4)
      },

      0xBE => lambda {
        op_ldx(get_addr_absolute_y_indexed)
        op_clock(4)
      },

      # LDY: load Y
      0xA0 => lambda {
        op_ldy(get_addr_immediate)
        op_clock(2)
      },

      0xA4 => lambda {
        op_ldy(get_addr_zero_page)
        op_clock(3)
      },

      0xB4 => lambda {
        op_ldy(get_addr_zero_page_x_indexed)
        op_clock(4)
      },

      0xAC => lambda {
        op_ldy(get_addr_absolute)
        op_clock(4)
      },

      0xBC => lambda {
        op_ldy(get_addr_absolute_y_indexed)
        op_clock(4)
      },

      # LSR: logical shift right

      # NOP: no operation
      0xEA => lambda {
        op_clock(2)
      },
      
      # ORA: inclusive or

      # PHA: push A
      0x48 => lambda {
        op_push(@reg_a.value)
        op_clock(3)
      },

      # PHP: push P
      0x08 => lambda {
        op_push(@reg_p.value)
        op_clock(3)
      },

      # PLA: pull A
      0x68 => lambda {
        @reg_a.value = op_pop
        op_test(@reg_a.value)
        op_clock(4)
      },

      # PLP: pull P
      0x28 => lambda {
        @reg_p.value = op_pop
        op_clock(4)
      },

      # ROL: rotate left
      # ROR: rorate right
      # RTI: return from interrupt
      # RTS: return from subroutine
      # SBC: subtract with carry

      # SEC: set carry
      0x38 => lambda {
        op_set_flag(CpuFlag::FLAG_C)
        op_clock(2)
      },

      # SED: set decimal flag
      0xF8 => lambda {
        op_set_flag(CpuFlag::FLAG_D)
        op_clock(2)
      },

      # SEI: set interrupt mask
      0x78 => lambda {
        op_set_flag(CpuFlag::FLAG_I)
        op_clock(2)
      },

      # STA: store A
      0x85 => lambda {
        op_st(get_addr_zero_page, @reg_a.value)
        op_clock(3)
      },

      0x95 => lambda {
        op_st(get_addr_zero_page_x_indexed, @reg_a.value)
        op_clock(4)
      },

      0x8D => lambda {
        op_st(get_addr_absolute, @reg_a.value)
        op_clock(4)
      },

      0x9D => lambda {
        op_st(get_addr_absolute_x_indexed, @reg_a.value)
        op_clock(4)
      },

      0x99 => lambda {
        op_st(get_addr_absolute_y_indexed, @reg_a.value)
        op_clock(4)
      },

      0x81 => lambda {
        op_st(get_addr_zero_page_indexed_indirect, @reg_a.value)
        op_clock(6)
      },

      0x91 => lambda {
        op_st(get_addr_zero_page_indirect_indexed, @reg_a.value)
        op_clock(6)
      },

      # STX: store X
      0x86 => lambda {
        op_st(get_addr_zero_page, @reg_x.value)
        op_clock(3)
      },

      0x96 => lambda {
        op_st(get_addr_zero_page_y_indexed, @reg_x.value)
        op_clock(4)
      },

      0x8E => lambda {
        op_st(get_addr_absolute, @reg_x.value)
        op_clock(4)
      },

      # STY: store Y
      0x84 => lambda {
        op_st(get_addr_zero_page, @reg_y.value)
        op_clock(3)
      },

      0x94 => lambda {
        op_st(get_addr_zero_page_x_indexed, @reg_y.value)
        op_clock(4)
      },

      0x8C => lambda {
        op_st(get_addr_absolute, @reg_y.value)
        op_clock(4)
      },

      # TAX: transfer A to X
      0xAA => lambda {
        @reg_x.value = @reg_a.value
        op_test(@reg_x.value)
        op_clock(2)
      },

      # TAY: transfer A to Y
      0xA8 => lambda {
        @reg_y.value = @reg_a.value
        op_test(@reg_y.value)
        op_clock(2)
      },

      # TSX: transfer SP to X
      0xBA => lambda {
        @reg_x.value = @reg_s.value
        op_test(@reg_x.value)
        op_clock(2)
      },

      # TXA: transfer X to A
      0x8A => lambda {
        @reg_a.value = @reg_x.value
        op_test(@reg_a.value)
        op_clock(2)
      },

      # TXS: transfer X to SP
      0x9A => lambda {
        @reg_s.value = @reg_x.value
        op_test(@reg_s.value)
        op_clock(2)
      },

      # TYA: transfer Y to A
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

  # Acc
  def get_addr_immediate
    addr16 = @reg_pc.value
    op_step
    return addr16
  end

  # ZP
  def get_addr_zero_page
    addr8 = op_read_byte(@reg_pc.value)
    op_step
    return 0x0000 + addr8
  end

  # ZP,X
  def get_addr_zero_page_x_indexed
    return get_addr_zero_page + @reg_x.value
  end

  # ZP,Y
  def get_addr_zero_page_y_indexed
    return get_addr_zero_page + @reg_y.value
  end

  # Abs
  def get_addr_absolute
    addr16_low = op_read_byte(@reg_pc.value)
    op_step
    addr16_high = op_read_byte(@reg_pc.value)
    op_step
    return (addr16_high << 8) + addr16_low
  end

  # Abs,X
  def get_addr_absolute_x_indexed
    return get_addr_absolute + @reg_x.value
  end

  # Abs,Y
  def get_addr_absolute_y_indexed
    return get_addr_absolute + @reg_y.value
  end

  # (ZP,X)
  def get_addr_zero_page_indexed_indirect
    return op_read_word(get_addr_zero_page + @reg_x.value)
  end

  # (ZP),Y
  def get_addr_zero_page_indirect_indexed
    return op_read_word(get_addr_zero_page) + @reg_y.value
  end

  def op_adc(addr16)
    @reg_a.value = @reg_a.value + op_read_byte(addr16) + @reg_p.get_flag(CpuFlag::FLAG_C)
    op_test_n(@reg_a.value)
    op_test_v(@reg_a.value)
    op_test_z(@reg_a.value)
    op_test_c(@reg_a.value)
  end

  def op_and(addr16)
    @reg_a.value &= op_read_byte(addr16)
    op_test_n(@reg_a.value)
    op_test_z(@reg_a.value)
  end

  def op_asl_val8(val8)
    if (val8 & 0x7f)
      @reg_p.set_flag(CpuFlag::FLAG_C)
    else
      @reg_p.clear_flag(CpuFlag::FLAG_C)
    end
    val8 = (val8 << 1) & 0xff
    op_test_n(val8)
    op_test_z(val8)
    op_test_c(val8)
    return val8
  end

  def op_asl(addr16)
    op_write_byte(addr16, op_asl_val8(op_read_byte(addr16)))
  end

  def op_branch(flag)
    offset = op_read_byte(@reg_pc.value)
    if flag
      @reg_pc = @reg_pc + offset
    else
      op_step
    end
  end

  def op_lda(addr16)
    @reg_a.value = op_read_byte(addr16)
    op_test(@reg_a.value)
  end

  def op_ldx(addr16)
    @reg_x.value = op_read_byte(addr16)
    op_test(@reg_x.value)
  end

  def op_ldy(addr16)
    @reg_y.value = op_read_byte(addr16)
    op_test(@reg_y.value)
  end

  def op_st(addr16, val8)
    op_write_byte(addr16, val8)
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

  def op_test_n(val8)
  end

  def op_test_v(val8)
  end

  def op_test_z(val8)
  end

  def op_test_c(val8)
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
