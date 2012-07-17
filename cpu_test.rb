#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'test/unit'
require './cpu'

class TC_cpu < Test::Unit::TestCase
  def setup
    @cpu = Cpu.new
    @cpu.reg_p.reset
    @old_flags = @cpu.reg_p.dup
    @old_pc = @cpu.reg_pc.dup
  end

  def step(code, step)
    @cpu.set_memory(code)
    @cpu.execute(step)
  end

  # def teardown
  # end

  # flag test
  def test_op_test_n_should_set_N_flag_with_0x80
    @cpu.op_test_n(0x80)
    assert_equal(@old_flags.set_n.value, @cpu.reg_p.value)
  end

  def test_op_test_n_should_clear_N_flag_with_0x00
    @cpu.op_test_n(0x00)
    assert_equal(@old_flags.clear_n.value, @cpu.reg_p.value)
  end

  def test_op_test_z_should_set_Z_flag_with_0x00
    @cpu.op_test_z(0x00)
    assert_equal(@old_flags.set_z.value, @cpu.reg_p.value)
  end

  def test_op_test_z_should_clear_Z_flag_with_0x01
    @cpu.op_test_z(0x01)
    assert_equal(@old_flags.clear_z.value, @cpu.reg_p.value)
  end

  def test_op_test_c_should_set_C_flag_with_0x100
    @cpu.op_test_c(0x100)
    assert_equal(@old_flags.set_c.value, @cpu.reg_p.value)
  end

  def test_op_test_c_should_clear_C_flag_with_0x000
    @cpu.op_test_c(0x000)
    assert_equal(@old_flags.clear_c.value, @cpu.reg_p.value)
  end

  def test_op_test_v_add_should_set_V_flag_with_0x40_plus_0x40
    @cpu.op_test_v_add(0x40 + 0x40, 0x40, 0x40)
    assert_equal(@old_flags.set_v.value, @cpu.reg_p.value)
  end

  def test_op_test_v_add_should_clear_V_flag_with_0x40_plus_0x3F
    @cpu.op_test_v_add(0x40 + 0x3F, 0x40, 0x3F)
    assert_equal(@old_flags.clear_v.value, @cpu.reg_p.value)
  end

  def test_op_test_v_add_should_set_V_flag_with_0x80_plus_0x80
    @cpu.op_test_v_add((0x80 + 0x80) & 0xFF, 0x80, 0x80)
    assert_equal(@old_flags.set_v.value, @cpu.reg_p.value)
  end

  # adressing mode
  def test_get_addr_immediate
    @cpu.reg_pc.value = 0xAAAA
    old_pc = @cpu.reg_pc.dup
    assert_equal(0xAAAA, @cpu.get_addr_immediate)
    assert_equal(old_pc.value + 1, @cpu.reg_pc.value)
  end

  def test_get_addr_zero_page
    @cpu.reg_pc.value = 0x01
    @cpu.set_memory([ 0x11, 0x22, 0x33 ])
    old_pc = @cpu.reg_pc.dup
    assert_equal(0x0022, @cpu.get_addr_zero_page)
    assert_equal(old_pc.value + 1, @cpu.reg_pc.value)
  end

  def test_get_addr_zero_page_x_indexed
    @cpu.reg_pc.value = 0x01
    @cpu.reg_x.value = 0x82
    @cpu.set_memory([ 0x55, 0x81, 0xAA ])
    old_pc = @cpu.reg_pc.dup
    assert_equal(0x0003, @cpu.get_addr_zero_page_x_indexed)
    assert_equal(old_pc.value + 1, @cpu.reg_pc.value)
  end

  def test_get_addr_zero_page_y_indexed
    @cpu.reg_pc.value = 0x01
    @cpu.reg_y.value = 0x82
    @cpu.set_memory([ 0x55, 0x81, 0xAA ])
    old_pc = @cpu.reg_pc.dup
    assert_equal(0x0003, @cpu.get_addr_zero_page_y_indexed)
    assert_equal(old_pc.value + 1, @cpu.reg_pc.value)
  end

  def test_get_addr_absolute
    @cpu.reg_pc.value = 0x01
    @cpu.set_memory([ 0x11, 0x22, 0x33 ])
    old_pc = @cpu.reg_pc.dup
    assert_equal(0x3322, @cpu.get_addr_absolute)
    assert_equal(old_pc.value + 2, @cpu.reg_pc.value)
  end

  def test_get_addr_absolute_x_indexed
    @cpu.reg_pc.value = 0x01
    @cpu.reg_x.value = 0x8A
    @cpu.set_memory([ 0x11, 0x80, 0xFF ])
    old_pc = @cpu.reg_pc.dup
    assert_equal(0x000A, @cpu.get_addr_absolute_x_indexed)
    assert_equal(old_pc.value + 2, @cpu.reg_pc.value)
  end

  def test_get_addr_absolute_y_indexed
    @cpu.reg_pc.value = 0x01
    @cpu.reg_y.value = 0x8A
    @cpu.set_memory([ 0x11, 0x80, 0xFF ])
    old_pc = @cpu.reg_pc.dup
    assert_equal(0x000A, @cpu.get_addr_absolute_y_indexed)
    assert_equal(old_pc.value + 2, @cpu.reg_pc.value)
  end

  def test_get_addr_zero_page_indexed_indirect
    @cpu.reg_pc.value = 0x01
    @cpu.reg_x.value = 0x82
    @cpu.set_memory([ 0x11, 0x80, 0xAA, 0x55 ])
    old_pc = @cpu.reg_pc.dup
    assert_equal(0x55AA, @cpu.get_addr_zero_page_indexed_indirect)
    assert_equal(old_pc.value + 1, @cpu.reg_pc.value)
  end

  def test_get_addr_zero_page_indirect_indexed
    @cpu.reg_pc.value = 0x01
    @cpu.reg_y.value = 0x81
    @cpu.set_memory([ 0x11, 0x02, 0x80, 0xFF ])
    old_pc = @cpu.reg_pc.dup
    assert_equal(0x0001, @cpu.get_addr_zero_page_indirect_indexed)
    assert_equal(old_pc.value + 1, @cpu.reg_pc.value)
  end

  def test_get_addr_indirect
    @cpu.reg_pc.value = 0x01
    @cpu.reg_y.value = 0x8A
    @cpu.set_memory([ 0x11, 0x03, 0x00, 0xAA, 0x55 ])
    old_pc = @cpu.reg_pc.dup
    assert_equal(0x55AA, @cpu.get_addr_indirect)
    assert_equal(old_pc.value + 2, @cpu.reg_pc.value)
  end

  # code test
  def test_and_flag_n
    @cpu.reg_a.value = 0b10101010
    step([ 0x2D, 0x03, 0x00, 0b11110000 ], 1)
    assert_equal(0b10100000, @cpu.reg_a.value)
    assert_equal(@old_flags.set_n.clear_z.value, @cpu.reg_p.value)
  end

  def test_and_flag_z
    @cpu.reg_a.value = 0b00001111
    step([ 0x2D, 0x03, 0x00, 0b11110000 ], 1)
    assert_equal(0b00000000, @cpu.reg_a.value)
    assert_equal(@old_flags.clear_n.set_z.value, @cpu.reg_p.value)
  end

  def test_sec_should_set_C_flag
    step([ 0x38 ], 1)
    assert_equal(@old_flags.set_c.value, @cpu.reg_p.value)
  end

  def test_sed_should_set_D_flag
    step([ 0xF8 ], 1)
    assert_equal(@old_flags.set_d.value, @cpu.reg_p.value)
  end

  def test_sei_should_set_I_flag
    step([ 0x78 ], 1)
    assert_equal(@old_flags.set_i.value, @cpu.reg_p.value)
  end

  def test_clc_should_clear_C_flag
    step([ 0x18 ], 1)
    assert_equal(@old_flags.clear_c.value, @cpu.reg_p.value)
  end

  def test_cld_should_clear_D_flag
    step([ 0xD8 ], 1)
    assert_equal(@old_flags.clear_d.value, @cpu.reg_p.value)
  end

  def test_cli_should_clear_I_flag
    step([ 0x58 ], 1)
    assert_equal(@old_flags.clear_i.value, @cpu.reg_p.value)
  end

  def test_adc
    @cpu.reg_a.value = 0x80
    @cpu.reg_p.clear_c
    step([ 0x6D, 0x03, 0x00, 0x80 ], 1)
    assert_equal((0x80 + 0x80 + 0) & 0xFF, @cpu.reg_a.value)
    assert_equal(@old_flags.clear_n.set_z.set_c.set_v.value, @cpu.reg_p.value)
  end
end

module AddressingModeTestRunner
  def setup
    @cpu = Cpu.new
    @cpu.reg_p.reset
    @old_flags = @cpu.reg_p.dup
    @old_pc = @cpu.reg_pc.dup
    pre_condition
  end

  def teardown
    post_condition
  end

  def step(code, step)
    @cpu.set_memory(code)
    @cpu.execute(step)
  end

  def test_addr_immediate
    if @op_code.has_key?('immediate')
      step( [@op_code['immediate']] + [ 0x7F ], 1)
    end
  end

  def test_addr_absolute
    if @op_code.has_key?('absolute')
      step( [@op_code['absolute']] + [ 0x03, 0x00, 0x7F ], 1)
    end
  end
end

class TC_adc < Test::Unit::TestCase
  include AddressingModeTestRunner

  def pre_condition
    @cpu.reg_a.value = 0x80
    @cpu.reg_p.set_c

    @op_code = {
      "immediate" => 0x69,
      "absolute" => 0x6D,
    }
  end

 def post_condition
   assert_equal((0x80 + 0x7F + 1) & 0xFF, @cpu.reg_a.value)
   assert_equal(@old_flags.clear_n.set_z.set_c.clear_v.value, @cpu.reg_p.value)
 end
end
