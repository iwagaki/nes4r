#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'test/unit'
require './cpu'

class TC_cpu < Test::Unit::TestCase
  def setup
    @cpu = Cpu.new
  end

  def step(code, step)
    @cpu.set_memory(code)
    @cpu.execute(step)
  end

  # def teardown
  # end

  def test_and_flag_n
    @cpu.reg_a.value = 0b10101010
    @cpu.reg_p.reset
    step([ 0x2D, 0x03, 0x00, 0b11110000 ], 1)
    assert_equal(0b10100000, @cpu.reg_a.value)
    assert_equal(1, @cpu.reg_p.get_flag(CpuFlag::FLAG_N))
    assert_equal(0, @cpu.reg_p.get_flag(CpuFlag::FLAG_Z))
  end

  def test_and_flag_z
    @cpu.reg_a.value = 0b00001111
    step([ 0x2D, 0x03, 0x00, 0b11110000 ], 1)
    assert_equal(0b00000000, @cpu.reg_a.value)
    assert_equal(0, @cpu.reg_p.get_flag(CpuFlag::FLAG_N))
    assert_equal(1, @cpu.reg_p.get_flag(CpuFlag::FLAG_Z))
  end

end
