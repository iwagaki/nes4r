#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require './bit_field'
require './cpu_flag'

BYTE = 0..7 # 1 byte = 8 bits
WORD = 0..15 # 1 word = 16 bits

class Cpu
  attr_accessor :reg_pc, :reg_a, :reg_x, :reg_y, :reg_s, :reg_p, :clock

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
        op_branch(@reg_p.get_flag(CpuFlag::FLAG_C) == 0)
        op_clock(2) # TODO
      },

      # BCS: branch on carry set
      0xB0 => lambda {
        op_branch(@reg_p.get_flag(CpuFlag::FLAG_C) == 1)
        op_clock(2) # TODO
      },

      # BEQ: branch if equal to zero
      0xF0 => lambda {
        op_branch(@reg_p.get_flag(CpuFlag::FLAG_Z) == 1)
        op_clock(2) # TODO
      },

      # BIT: bit test (compare memory bits with A)
      0x2C => lambda {
        op_bit(get_addr_absolute)
        op_clock(4)
      },

      0x24 => lambda {
        op_bit(get_addr_zero_page)
        op_clock(4)
      },

      # BMI: branch on minus
      0x30 => lambda {
        op_branch(@reg_p.get_flag(CpuFlag::FLAG_N) == 1)
        op_clock(2) # TODO
      },

      # BNE: branch if not equal to zero
      0xD0 => lambda {
        op_branch(@reg_p.get_flag(CpuFlag::FLAG_Z) == 0)
        op_clock(2) # TODO
      },

      # BPL: branch on plus
      0x10 => lambda {
        op_branch(@reg_p.get_flag(CpuFlag::FLAG_N) == 0)
        op_clock(2) # TODO
      },

      # BRK: break
      0x00 => lambda {
        op_pushw(@reg_pc.value)
        @reg_p.set_flag(CpuFlag::FLAG_B)
        op_push(@reg_p.value)
        @reg_p.set_flag(CpuFlag::FLAG_I)
        @reg_pc.value = op_read_word(0xFFFE)
        op_clock(7)
      },

      # BVC: branch on overflow clear
      0x50 => lambda {
        op_branch(@reg_p.get_flag(CpuFlag::FLAG_V) == 0)
        op_clock(2) # TODO
      },

      # BVS: branch on overflow set
      0x70 => lambda {
        op_branch(@reg_p.get_flag(CpuFlag::FLAG_N) == 1)
        op_clock(2) # TODO
      },

      # CLC: clear carry
      0x18 => lambda {
        @reg_p.clear_c
        op_clock(2)
      },

      # CLD: clear decimal flag
      0xD8 => lambda {
        @reg_p.clear_d
        op_clock(2)
      },

      # CLI: clear interrupt mask
      0x58 => lambda {
        @reg_p.clear_i
        op_clock(2)
      },

      # CLV: clear overflow flag
      0xB8 => lambda {
        op_clear_flag(CpuFlag::FLAG_V)
        op_clock(2)
      },

      # CMP: compare to A
      0xCD => lambda {
        op_cmp(@reg_a.value, get_addr_absolute)
        op_clock(4)
      },

      0xC5 => lambda {
        op_cmp(@reg_a.value, get_addr_zero_page)
        op_clock(3)
      },

      0xC9 => lambda {
        op_cmp(@reg_a.value, get_addr_immediate)
        op_clock(2)
      },

      0xDD => lambda {
        op_cmp(@reg_a.value, get_addr_absolute_x_indexed)
        op_clock(4) # TODO
      },

      0xD9 => lambda {
        op_cmp(@reg_a.value, get_addr_absolute_y_indexed)
        op_clock(4) # TODO
      },

      0xC1 => lambda {
        op_cmp(@reg_a.value, get_addr_zero_page_indexed_indirect)
        op_clock(6)
      },

      0xD1 => lambda {
        op_cmp(@reg_a.value, get_addr_zero_page_indirect_indexed)
        op_clock(5) # TODO
      },

      0xD5 => lambda {
        op_cmp(@reg_a.value, get_addr_zero_page_x_indexed)
        op_clock(4)
      },

      # CPX: compare to X
      0xEC => lambda {
        op_cmp(@reg_x.value, get_addr_absolute)
        op_clock(4)
      },

      0xE4 => lambda {
        op_cmp(@reg_x.value, get_addr_zero_page)
        op_clock(3)
      },

      0xEC => lambda {
        op_cmp(@reg_x.value, get_addr_immediate)
        op_clock(2)
      },

      # CPY: compare to Y
      0xCC => lambda {
        op_cmp(@reg_y.value, get_addr_absolute)
        op_clock(4)
      },

      0xC4 => lambda {
        op_cmp(@reg_y.value, get_addr_zero_page)
        op_clock(3)
      },

      0xC0 => lambda {
        op_cmp(@reg_y.value, get_addr_immediate)
        op_clock(2)
      },

      # DEC: decrement
      0xCE => lambda {
        op_dec(get_addr_absolute)
        op_clock(6)
      },

      0xC6 => lambda {
        op_dec(get_addr_zero_page)
        op_clock(5)
      },

      0xDE => lambda {
        op_dec(get_addr_absolute_x_indexed)
        op_clock(7)
      },

      0xD6 => lambda {
        op_dec(get_addr_zero_page_x_indexed)
        op_clock(6)
      },

      # DEX: decrement X
      0xCA => lambda {
        @reg_x.value -= 1
        op_test_n(@reg_x.value)
        op_test_z(@reg_x.value)
        op_clock(2)
      },

      # DEY: decrement Y
      0x88 => lambda {
        @reg_y.value -= 1
        op_test_n(@reg_y.value)
        op_test_z(@reg_y.value)
        op_clock(2)
      },

      # EOR: exclusive or
      0x4D => lambda {
        op_eor(get_addr_absolute)
        op_clock(4)
      },

      0x45 => lambda {
        op_eor(get_addr_zero_page)
        op_clock(3)
      },

      0x49 => lambda {
        op_eor(get_addr_immediate)
        op_clock(2)
      },

      0x5D => lambda {
        op_eor(get_addr_absolute_x_indexed)
        op_clock(4)
      },

      0x59 => lambda {
        op_eor(get_addr_absolute_y_indexed)
        op_clock(4)
      },

      0x41 => lambda {
        op_eor(get_addr_zero_page_indexed_indirect)
        op_clock(6)
      },

      0x51 => lambda {
        op_eor(get_addr_zero_page_indirect_indexed)
        op_clock(5)
      },

      0x55 => lambda {
        op_eor(get_addr_zero_page_x_indexed)
        op_clock(4)
      },

      # INC: increment
      0xEE => lambda {
        op_inc(get_addr_absolute)
        op_clock(6)
      },

      0xE6 => lambda {
        op_inc(get_addr_zero_page)
        op_clock(5)
      },

      0xFE => lambda {
        op_inc(get_addr_absolute_x_indexed)
        op_clock(7)
      },

      0xF6 => lambda {
        op_inc(get_addr_zero_page_x_indexed)
        op_clock(6)
      },

      # INX: increment X
      0xE8 => lambda {
        @reg_x.value += 1
        op_test_n(@reg_x.value)
        op_test_z(@reg_x.value)
        op_clock(2)
      },

      # INY: increment Y
      0xC8 => lambda {
        @reg_y.value += 1
        op_test_n(@reg_y.value)
        op_test_z(@reg_y.value)
        op_clock(2)
      },

      # JMP: jump
      0x4C => lambda {
        op_jump(get_addr_absolute)
        op_clock(3)
      },

      0x6C => lambda {
        op_jump(get_addr_indirect)
        op_clock(5)
      },
      
      # JSR: jump to subroutine
      0x6C => lambda {
        val8 = op_read_byte(@reg_pc.value)
        op_step
        op_pushw(@reg_pc.value)
        #TODP
      },

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
      0x0D => lambda {
        op_ora(get_addr_absolute)
        op_clock(4)
      },

      0x05 => lambda {
        op_ora(get_addr_zero_page)
        op_clock(3)
      },

      0x09 => lambda {
        op_ora(get_addr_immediate)
        op_clock(2)
      },

      0x1D => lambda {
        op_ora(get_addr_absolute_x_indexed)
        op_clock(4)
      },

      0x19 => lambda {
        op_ora(get_addr_absolute_y_indexed)
        op_clock(4)
      },

      0x01 => lambda {
        op_ora(get_addr_zero_page_indexed_indirect)
        op_clock(6)
      },

      0x11 => lambda {
        op_ora(get_addr_zero_page_indirect_indexed)
        op_clock(5)
      },

      0x15 => lambda {
        op_ora(get_addr_zero_page_x_indexed)
        op_clock(4)
      },

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
        op_test_n(@reg_a.value)
        op_test_z(@reg_a.value)
        op_clock(4)
      },

      # PLP: pull P
      0x28 => lambda {
        @reg_p.value = op_pop
        op_clock(4)
      },

      # ROL: rotate left
      0x2A => lambda {
        val8 = @reg_a.value
        carry = val8 >> 7
        @reg_a.value = (val8 << 1) | carry
        op_test_n(val8)
        op_test_z(val8)
        @reg_p.set_flag(CpuFlag::FLAG_C, carry)
        op_clock(2)
      },

      0x2E => lambda {
        op_rol(get_addr_absolute)
        op_clock(6)
      },

      0x26 => lambda {
        op_rol(get_addr_zero_page)
        op_clock(5)
      },

      0x3E => lambda {
        op_rol(get_addr_absolute_x_indexed)
        op_clock(7)
      },

      0x36 => lambda {
        op_rol(get_addr_zero_page_x_indexed)
        op_clock(6)
      },

      # ROR: rorate right
      0x6A => lambda {
        val8 = @reg_a.value
        carry = val8 & 0x1
        @reg_a.value = (val8 >> 1) | (carry << 7)
        op_test_n(val8)
        op_test_z(val8)
        @reg_p.set_flag(CpuFlag::FLAG_C, carry)
        op_clock(2)
      },

      0x6E => lambda {
        op_ror(get_addr_absolute)
        op_clock(6)
      },

      0x66 => lambda {
        op_ror(get_addr_zero_page)
        op_clock(5)
      },

      0x7E => lambda {
        op_ror(get_addr_absolute_x_indexed)
        op_clock(7)
      },

      0x76 => lambda {
        op_ror(get_addr_zero_page_x_indexed)
        op_clock(6)
      },

      # RTI: return from interrupt
      0x40 => lambda {
        @reg_p.value = op_pop
        @reg_pc.value = op_popw
        op_clock(6)
      },

      # RTS: return from subroutine
      0x60 => lambda {
        @reg_pc.value = op_popw
        op_clock(6)
      },

      # SBC: subtract with carry
      0xED => lambda {
        op_sbc(get_addr_absolute)
        op_clock(4)
      },

      0xE5 => lambda {
        op_sbc(get_addr_zero_page)
        op_clock(3)
      },

      0xE9 => lambda {
        op_sbc(get_addr_immediate)
        op_clock(2)
      },

      0xFD => lambda {
        op_sbc(get_addr_absolute_x_indexed)
        op_clock(4)
      },

      0xF9 => lambda {
        op_sbc(get_addr_absolute_y_indexed)
        op_clock(4)
      },

      0xE1 => lambda {
        op_sbc(get_addr_zero_page_indexed_indirect)
        op_clock(6)
      },

      0xF1 => lambda {
        op_sbc(get_addr_zero_page_indirect_indexed)
        op_clock(5)
      },

      0xF5 => lambda {
        op_sbc(get_addr_zero_page_x_indexed)
        op_clock(4)
      },

      # SEC: set carry
      0x38 => lambda {
        @reg_p.set_c
        op_clock(2)
      },

      # SED: set decimal flag
      0xF8 => lambda {
        @reg_p.set_d
        op_clock(2)
      },

      # SEI: set interrupt mask
      0x78 => lambda {
        @reg_p.set_i
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
        op_test_n(@reg_x.value)
        op_test_z(@reg_x.value)
        op_clock(2)
      },

      # TAY: transfer A to Y
      0xA8 => lambda {
        @reg_y.value = @reg_a.value
        op_test_n(@reg_y.value)
        op_test_z(@reg_y.value)
        op_clock(2)
      },

      # TSX: transfer SP to X
      0xBA => lambda {
        @reg_x.value = @reg_s.value
        op_test_n(@reg_x.value)
        op_test_z(@reg_x.value)
        op_clock(2)
      },

      # TXA: transfer X to A
      0x8A => lambda {
        @reg_a.value = @reg_x.value
        op_test_n(@reg_a.value)
        op_test_z(@reg_a.value)
        op_clock(2)
      },

      # TXS: transfer X to SP
      0x9A => lambda {
        @reg_s.value = @reg_x.value
        op_test_n(@reg_s.value)
        op_test_z(@reg_s.value)
        op_clock(2)
      },

      # TYA: transfer Y to A
      0x98 => lambda {
        @reg_a.value = @reg_y.value
        op_test_n(@reg_a.value)
        op_test_z(@reg_a.value)
        op_clock(2)
      },
    }
  end

  def op_read_byte(addr16)
    raise "Error: Out of memory" if addr16 >= @memory.size
    return @memory[addr16]
  end

  def op_read_word(addr16)
    raise "Error: Out of memory" if addr16 + 1 >= @memory.size
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

  def op_pushw(val16)
    op_push(val16 >> 8)
    op_push(val16 & 0xff)
  end

  def op_popw
    val8 = op_pop
    return (op_pop << 8) | val8
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
    return addr8
  end

  # ZP,X
  def get_addr_zero_page_x_indexed
    return (get_addr_zero_page + @reg_x.value) & 0xFF
  end

  # ZP,Y
  def get_addr_zero_page_y_indexed
    return (get_addr_zero_page + @reg_y.value) & 0xFF
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
    return (get_addr_absolute + @reg_x.value) & 0xFFFF
  end

  # Abs,Y
  def get_addr_absolute_y_indexed
    return (get_addr_absolute + @reg_y.value) & 0xFFFF
  end

  # (ZP,X)
  def get_addr_zero_page_indexed_indirect
    return op_read_word(get_addr_zero_page_x_indexed)
  end

  # (ZP),Y
  def get_addr_zero_page_indirect_indexed
    return (op_read_word(get_addr_zero_page) + @reg_y.value) & 0xFFFF
  end

  # Indirect
  def get_addr_indirect
    return op_read_word(get_addr_absolute)
  end

  # Relative
  def get_addr_relative
    val8 = op_read_byte(@reg_pc.value)
    borrow = (val8 & 0x80 == 0) ? 0 : 0x100
    return (@reg_pc.value + val8 - borrow) & 0xFFFF
  end

  def op_adc(addr16)
    op1 = @reg_a.value
    op2 = op_read_byte(addr16)
    val16 = op1 + op2 + @reg_p.get_flag(CpuFlag::FLAG_C)
    val8 = val16 & 0xFF
    op_test_n(val8)
    op_test_z(val8)
    op_test_c(val16)
    op_test_v_add(val8, op1, op2)
    @reg_a.value = val8
  end

  def op_and(addr16)
    @reg_a.value &= op_read_byte(addr16)
    op_test_n(@reg_a.value)
    op_test_z(@reg_a.value)
  end

  def op_bit(addr16)
    val8 = (@reg_a.value & op_read_byte(addr16)) & 0xff
    op_test_n(val8)
    op_test_z(val8)
    @reg_p.set_flag(CpuFlag::FLAG_V, (val8 >> 6) & 0x1)

  end

  def op_cmp(val8, addr16)
    tmp_val8 = (val8 - op_read_byte(addr16)) & 0xff
    op_test_n(tmp_val8)
    op_test_z(tmp_val8)
    op_test_c(tmp_val8)
  end

  def op_asl_val8(val8)
    @reg_p.set_flag(CpuFlag::FLAG_C, val8 >> 7)

    val8 = (val8 << 1) & 0xff
    op_test_n(val8)
    op_test_z(val8)
    return val8
  end

  def op_asl(addr16)
    op_write_byte(addr16, op_asl_val8(op_read_byte(addr16)))
  end

  def op_ror(addr16)
    val8 = op_read_byte(add16)
    carry = val8 & 0x1
    val8 = (val8 >> 1) | (carry << 7)
    op_write_byte(addr16, val8)
    op_test_n(val8)
    op_test_z(val8)
    @reg_p.set_flag(CpuFlag::FLAG_C, carry)

  end

  def op_rol(addr16)
    val8 = op_read_byte(add16)
    carry = val8 >> 7
    val8 = (val8 << 1) | carry
    op_write_byte(addr16, val8)
    op_test_n(val8)
    op_test_z(val8)
    @reg_p.set_flag(CpuFlag::FLAG_C, carry)
  end

  def op_sbc(addr16)
    @reg_a.value = @reg_a.value - op_read_byte(addr16) - @reg_p.get_flag(CpuFlag::FLAG_C)
    op_test_n(@reg_a.value)
    op_test_v_sbc(@reg_a.value)
    op_test_z(@reg_a.value)
    op_test_c(@reg_a.value)
  end

  def op_branch(flag)
    addr16 = get_addr_relative
    if flag
      @reg_pc = (@reg_pc + offset) & 0xFFFF
    end
  end

  def op_jump(addr16)
    @reg_pc.value = op_read_word(addr16)
  end

  def op_dec(addr16)
    val8 = op_read_byte(addr16) - 1
    op_test_z(val8)
    op_test_n(val8)
    op_write_byte(addr16, val8)
  end

  def op_dec(addr16)
    val8 = op_read_byte(addr16) + 1
    op_test_z(val8)
    op_test_n(val8)
    op_write_byte(addr16, val8)
  end

  def op_eor(addr16)
    @reg_a.value = @reg_a.value ^ op_read_byte(addr16)
    op_test_n(@reg_a.value)
    op_test_z(@reg_a.value)
  end

  def op_ora(addr16)
    @reg_a.value = @reg_a.value | op_read_byte(addr16)
    op_test_n(@reg_a.value)
    op_test_z(@reg_a.value)
  end

  def op_lda(addr16)
    @reg_a.value = op_read_byte(addr16)
    op_test_n(@reg_a.value)
    op_test_z(@reg_a.value)
  end

  def op_ldx(addr16)
    @reg_x.value = op_read_byte(addr16)
    op_test_n(@reg_x.value)
    op_test_z(@reg_x.value)
  end

  def op_ldy(addr16)
    @reg_y.value = op_read_byte(addr16)
    op_test_n(@reg_y.value)
    op_test_z(@reg_y.value)
  end

  def op_st(addr16, val8)
    op_write_byte(addr16, val8)
  end

  def op_clock(n)
    @clock += n
  end

  def op_step(n = 1)
    @reg_pc.value = (@reg_pc.value + n) & 0xFFFF
  end

  def op_test_n(val8)
    @reg_p.set_n(val8 & 0x80 != 0)
  end

  def op_test_z(val8)
    @reg_p.set_z(val8 == 0)
  end

  def op_test_c(val16)
    @reg_p.set_c(val16 & 0x100 != 0)
  end

  def op_test_v_add(c, a, b) # c = a + b
    @reg_p.set_v(((a ^ b) ^ 0x80) & (a ^ c) & 0x80 != 0)
  end

  def op_test_v_sub(c, a, b) # c = a - b
    @reg_p.clear_flag(CpuFlag::FLAG_V)
    @reg_p.set_flag(CpuFlag::FLAG_V) if (a ^ b) & (a ^ c) & 0x80 != 0
    #TODO
  end


  def set_memory(memory)
    @memory = memory
  end

  def dump
    puts sprintf("PC:%04X CLK:%04d A:%02X X:%02X Y:%02X S:%02X %s",
                 @reg_pc.value, @clock, @reg_a.value, @reg_x.value, @reg_y.value, @reg_s.value, @reg_p.to_s)
  end

  def execute(max_step = nil)
    step_count = 0
    while @reg_pc.value < @memory.size
      if max_step != nil && step_count >= max_step
        break
      end
#      dump
      opcode = op_read_byte(get_addr_immediate)
      @instruction_map[opcode].call
      step_count += 1
    end
#    dump
  end
end

def main
  cpu = Cpu.new

  # memory map
  # 0x0000 - 0x00FF: Page Zero
  # 0x0100 - 0x01FF: Page One (Stack)
  # 0xFFFA - 0xFFFB: Non-maskabale interrupt vector
  # 0xFFFC - 0xFFFD: Reset vector
  # 0xFFFE - 0xFFFF: Maskable interrupt vector
  # 0x10000 - Registers
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
end

if __FILE__ == $0
  main
end
