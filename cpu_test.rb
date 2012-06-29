#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'test/unit'
require './cpu'

class TC_cpu < Test::Unit::TestCase
  def setup
    @cpu = Cpu.new
    @cpu.reg_p.reset
    @old_flags = @cpu.reg_p.dup
  end

  def step(code, step)
    @cpu.set_memory(code)
    @cpu.execute(step)
  end

  # def teardown
  # end

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

  def test_sec
    step([ 0x38 ], 1)
    assert_equal(@old_flags.set_c.value, @cpu.reg_p.value)
  end

  def test_sed
    step([ 0xF8 ], 1)
    assert_equal(@old_flags.set_d.value, @cpu.reg_p.value)
  end

  def test_sei
    step([ 0x78 ], 1)
    assert_equal(@old_flags.set_i.value, @cpu.reg_p.value)
  end
end
