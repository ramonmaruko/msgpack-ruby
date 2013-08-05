# encoding: ascii-8bit
require 'spec_helper'

describe MessagePack do
  it "nil" do
    check 1, nil
  end

  it "true" do
    check 1, true
  end

  it "false" do
    check 1, false
  end

  it "zero" do
    check 1, 0
  end

  it "positive fixnum" do
    check 1, 1
    check 1, (1<<6)
    check 1, (1<<7)-1
  end

  it "positive int 8" do
    check 1, -1
    check 2, (1<<7)
    check 2, (1<<8)-1
  end

  it "positive int 16" do
    check 3, (1<<8)
    check 3, (1<<16)-1
  end

  it "positive int 32" do
    check 5, (1<<16)
    check 5, (1<<32)-1
  end

  it "positive int 64" do
    check 9, (1<<32)
    #check 9, (1<<64)-1
  end

  it "negative fixnum" do
    check 1, -1
    check 1, -((1<<5)-1)
    check 1, -(1<<5)
  end

  it "negative int 8" do
    check 2, -((1<<5)+1)
    check 2, -(1<<7)
  end

  it "negative int 16" do
    check 3, -((1<<7)+1)
    check 3, -(1<<15)
  end

  it "negative int 32" do
    check 5, -((1<<15)+1)
    check 5, -(1<<31)
  end

  it "negative int 64" do
    check 9, -((1<<31)+1)
    check 9, -(1<<63)
  end

  it "double" do
    check 9, 1.0
    check 9, 0.1
    check 9, -0.1
    check 9, -1.0
  end

  it "fixraw" do
    check_raw 1, 0
    check_raw 1, (1<<5)-1
  end

  it "raw 16" do
    check_raw 3, (1<<5)
    check_raw 3, (1<<16)-1
  end

  it "raw 32" do
    check_raw 5, (1<<16)
    #check_raw 5, (1<<32)-1  # memory error
  end

  it "fixarray" do
    check_array 1, 0
    check_array 1, (1<<4)-1
  end

  it "array 16" do
    check_array 3, (1<<4)
    #check_array 3, (1<<16)-1
  end

  it "array 32" do
    #check_array 5, (1<<16)
    #check_array 5, (1<<32)-1  # memory error
  end

  it "fixext 1" do
    check_ext 2, 1, -128
    check_ext 2, 1, 1
    check_ext 2, 1, 127
  end

  it "fixext 2" do
    check_ext 2, 2, -128
    check_ext 2, 2, 1
    check_ext 2, 2, 127
  end

  it "fixext 4" do
    check_ext 2, 4, -128
    check_ext 2, 4, 1
    check_ext 2, 4, 127
  end

  it "fixext 8" do
    check_ext 2, 8, -128
    check_ext 2, 8, 1
    check_ext 2, 8, 127
  end

  it "fixext 16" do
    check_ext 2, 16, -128
    check_ext 2, 16, 1
    check_ext 2, 16, 127
  end


  it "ext 8" do
    check_ext 3, (1<<8) - 1, -128
    check_ext 3, (1<<8) - 1, 1
    check_ext 3, (1<<8) - 2, 127
  end

  it "ext 16" do
    check_ext 4, (1<<16) - 1, -128
    check_ext 4, (1<<8), 1
    check_ext 4, (1<<16) - 2, 127
  end

  it "ext 32" do
    check_ext 6, (1<<20), -128
    check_ext 6, (1<<16), 1
    check_ext 6, (1<<16), 127
  end


  it "nil" do
    match nil, "\xc0"
  end

  it "false" do
    match false, "\xc2"
  end

  it "true" do
    match true, "\xc3"
  end

  it "0" do
    match 0, "\x00"
  end

  it "127" do
    match 127, "\x7f"
  end

  it "128" do
    match 128, "\xcc\x80"
  end

  it "256" do
    match 256, "\xcd\x01\x00"
  end

  it "-1" do
    match -1, "\xff"
  end

  it "-33" do
    match -33, "\xd0\xdf"
  end

  it "-129" do
    match -129, "\xd1\xff\x7f"
  end

  it "{1=>1}" do
    obj = {1=>1}
    match obj, "\x81\x01\x01"
  end

  it "1.0" do
    match 1.0, "\xcb\x3f\xf0\x00\x00\x00\x00\x00\x00"
  end

  it "[]" do
    match [], "\x90"
  end

  it "[0, 1, ..., 14]" do
    obj = (0..14).to_a
    match obj, "\x9f\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e"
  end

  it "[0, 1, ..., 15]" do
    obj = (0..15).to_a
    match obj, "\xdc\x00\x10\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f"
  end

  it "{}" do
    obj = {}
    match obj, "\x80"
  end

  it "extended type 1 with payload aa" do
    obj = MessagePack::Extended.new(1, "aa")
    match obj, "\xd5\x01aa"
  end

  it "extended type 1 with payload aaaa" do
    obj = MessagePack::Extended.new(1, "aaaa")
    match obj, "\xd6\x01aaaa"
  end

  it "extended type 1 with payload aaaa" do
    obj = MessagePack::Extended.new(1, "aaaa")
    match obj, "\xd6\x01aaaa"
  end

  it "extended type 1 with payload aaaaaaaa" do
    obj = MessagePack::Extended.new(1, "aaaaaaaa")
    match obj, "\xd7\x01aaaaaaaa"
  end

  it "extended type 1 with a payload of 2^8 - 1 bytes" do
    size = (1<<8) - 1
    obj = MessagePack::Extended.new(1, "a" * size)
    match obj, "\xc7\xff\x01" << ("a" * size)
  end

  it "extended type 1 with a payload of 2^16 - 1 bytes" do
    size = (1<<16) - 1
    obj = MessagePack::Extended.new(1, "a" * size)
    match obj, "\xc8\xff\xff\x01" << ("a" * size)
  end

  it "extended type 1 with a payload of 2^16 - 2 bytes" do
    size = (1<<16) - 2
    obj = MessagePack::Extended.new(1, "a" * size)
    match obj, "\xc8\xff\xfe\x01" << ("a" * size)
  end

  it "extended type 1 with a payload of 2^16" do
    size = (1<<16)
    obj = MessagePack::Extended.new(1, "a" * size)
    match obj, "\xc9\x00\x01\x00\x00\x01" << ("a" * size)
  end

  it "extended type 1 with a payload of 2^16 + 1" do
    size = (1<<16) + 1
    obj = MessagePack::Extended.new(1, "a" * size)
    match obj, "\xc9\x00\x01\x00\x01\x01" << ("a" * size)
  end

  describe "Time packing" do
    # test range of seconds
    it "Time -(1 << 7)" do
      obj = Time.at(-(1 << 7)).utc
      match obj, "\xd5\xfe\x80\x80"
    end

    it "Time -(1 << 15)" do
      obj = Time.at(-(1 << 15)).utc
      match obj, "\xc7\x03\xfe\x84\x80\x00"
    end

    it "Time -(1 << 23)" do
      obj = Time.at(-(1 << 23)).utc
      match obj, "\xd6\xfe\x88\x80\x00\x00"
    end

    it "Time -(1 << 31)" do
      obj = Time.at(-(1 << 31)).utc
      match obj, "\xc7\x05\xfe\x8C\x80\x00\x00\x00"
    end

    it "Time -(1 << 39)" do
      obj = Time.at(-(1 << 39)).utc
      match obj, "\xc7\x06\xfe\x90\x80\x00\x00\x00\x00"
    end

    it "Time -(1 << 47)" do
      obj = Time.at(-(1 << 47)).utc
      match obj, "\xc7\x07\xfe\x94\x80\x00\x00\x00\x00\x00"
    end

    it "Time -(1 << 55)" do
      obj = Time.at(-(1 << 55)).utc
      match obj, "\xd7\xfe\x98\x80\x00\x00\x00\x00\x00\x00"
    end

    it "Time -(1 << 63)" do
      obj = Time.at(-(1 << 63)).utc
      match obj, "\xc7\x09\xfe\x9c\x80\x00\x00\x00\x00\x00\x00\x00"
    end

    it "Time (1 << 7) - 1" do
      obj = Time.at((1 << 7) - 1).utc
      match obj, "\xd5\xfe\x80\x7f"
    end

    it "Time (1 << 15) - 1" do
      obj = Time.at((1 << 15) - 1).utc
      match obj, "\xc7\x03\xfe\x84\x7f\xff"
    end

    it "Time (1 << 23) - 1" do
      obj = Time.at((1 << 23) - 1).utc
      match obj, "\xd6\xfe\x88\x7f\xff\xff"
    end

    it "Time (1 << 31) - 1" do
      obj = Time.at((1 << 31) - 1).utc
      match obj, "\xc7\x05\xfe\x8c\x7f\xff\xff\xff"
    end

    it "Time (1 << 39) - 1" do
      obj = Time.at((1 << 39) - 1).utc
      match obj, "\xc7\x06\xfe\x90\x7f\xff\xff\xff\xff"
    end

    it "Time (1 << 47) - 1" do
      obj = Time.at((1 << 47) - 1).utc
      match obj, "\xc7\x07\xfe\x94\x7f\xff\xff\xff\xff\xff"
    end

    it "Time (1 << 55) - 1" do
      obj = Time.at((1 << 55) - 1).utc
      match obj, "\xd7\xfe\x98\x7f\xff\xff\xff\xff\xff\xff"
    end

    it "Time (1 << 63) - 1" do
      obj = Time.at((1 << 63) - 1).utc
      match obj, "\xc7\x09\xfe\x9c\x7f\xff\xff\xff\xff\xff\xff\xff"
    end

    # test upper bounds
    it "Time (1 << 7)" do
      obj = Time.at((1 << 7)).utc
      match obj, "\xc7\x03\xfe\x84\x00\x80"
    end

    it "Time (1 << 15)" do
      obj = Time.at((1 << 15)).utc
      match obj, "\xd6\xfe\x88\x00\x80\x00"
    end

    it "Time (1 << 23)" do
      obj = Time.at((1 << 23)).utc
      match obj, "\xc7\x05\xfe\x8c\x00\x80\x00\x00"
    end

    it "Time (1 << 31)" do
      obj = Time.at((1 << 31)).utc
      match obj, "\xc7\x06\xfe\x90\x00\x80\x00\x00\x00"
    end

    it "Time (1 << 39)" do
      obj = Time.at((1 << 39)).utc
      match obj, "\xc7\x07\xfe\x94\x00\x80\x00\x00\x00\x00"
    end

    it "Time (1 << 47)" do
      obj = Time.at((1 << 47)).utc
      match obj, "\xd7\xfe\x98\x00\x80\x00\x00\x00\x00\x00"
    end

    it "Time (1 << 55)" do
      obj = Time.at((1 << 55)).utc
      match obj, "\xc7\x09\xfe\x9c\x00\x80\x00\x00\x00\x00\x00\x00"
    end

    it "Time (1 << 63)" do
      expect {
        Time.at((1 << 63)).utc.to_msgpack
      }.to raise_error RangeError

    end

    # test two's complement for seconds
    it "Time -(1 << 7) + 1" do
      obj = Time.at(-(1 << 7) +1).utc
      match obj, "\xd5\xfe\x80\x81"
    end

    it "Time -(1 << 15) + 1" do
      obj = Time.at(-(1 << 15) + 1).utc
      match obj, "\xc7\x03\xfe\x84\x80\x01"
    end

    it "Time -(1 << 23 + 1)" do
      obj = Time.at(-(1 << 23) + 1).utc
      match obj, "\xd6\xfe\x88\x80\x00\x01"
    end

    it "Time -(1 << 31) + 1" do
      obj = Time.at(-(1 << 31) + 1).utc
      match obj, "\xc7\x05\xfe\x8C\x80\x00\x00\x01"
    end

    it "Time -(1 << 39) + 1" do
      obj = Time.at(-(1 << 39) + 1).utc
      match obj, "\xc7\x06\xfe\x90\x80\x00\x00\x00\x01"
    end

    it "Time -(1 << 47) + 1" do
      obj = Time.at(-(1 << 47) + 1).utc
      match obj, "\xc7\x07\xfe\x94\x80\x00\x00\x00\x00\x01"
    end

    it "Time -(1 << 55) + 1" do
      obj = Time.at(-(1 << 55) + 1).utc
      match obj, "\xd7\xfe\x98\x80\x00\x00\x00\x00\x00\x01"
    end

    it "Time -(1 << 63) + 1" do
      obj = Time.at(-(1 << 63) + 1).utc
      match obj, "\xc7\x09\xfe\x9C\x80\x00\x00\x00\x00\x00\x00\x01"
    end

    # test range of nsec with no seconds
    it "Time nsec (1 << 8) - 1" do
      nsec = Rational((1 << 8) - 1, 1_000_000_000)
      obj = Time.at(nsec).utc
      match obj, "\xd5\xfe\x40\xff"
    end

    it "Time nsec (1 << 16) - 1" do
      nsec = Rational((1 << 16) - 1, 1_000_000_000)
      obj = Time.at(nsec).utc
      match obj, "\xc7\x03\xfe\x41\xff\xff"
    end

    it "Time nsec (1 << 24) - 1" do
      nsec = Rational((1 << 24) - 1, 1_000_000_000)
      obj = Time.at(nsec).utc
      match obj, "\xd6\xfe\x42\xff\xff\xff"
    end

    it "Time 999_999_999ns" do
      nsec = Rational(1) - Rational(1, 1_000_000_000)
      obj = Time.at(nsec).utc
      match obj, "\xc7\x05\xfe\x43\x3b\x9a\xc9\xff"
    end

    # test upper bounds
    it "Time nsec (1 << 8)" do
      nsec = Rational((1 << 8), 1_000_000_000)
      obj = Time.at(nsec).utc
      match obj, "\xc7\x03\xfe\x41\x01\x00"
    end

    it "Time nsec (1 << 16)" do
      nsec = Rational((1 << 16), 1_000_000_000)
      obj = Time.at(nsec).utc
      match obj, "\xd6\xfe\x42\x01\x00\x00"
    end

    it "Time nsec (1 << 24)" do
      nsec = Rational((1 << 24), 1_000_000_000)
      obj = Time.at(nsec).utc
      match obj, "\xc7\x05\xfe\x43\x01\x00\x00\x00"
    end


    # seconds with 999_999_999ns
    it "Time -(1 << 7)s 999_999_999ns" do
      obj = Time.at(-(1 << 7) + Rational(1) - Rational(1, 1_000_000_000)).utc
      match obj, "\xc7\x06\xfe\xc3\x80\x3b\x9a\xc9\xff"
    end

    it "Time -(1 << 15)s 999_999_999ns" do
      obj = Time.at(-(1 << 15) + Rational(1) - Rational(1, 1_000_000_000)).utc
      match obj, "\xc7\x07\xfe\xc7\x80\x00\x3b\x9a\xc9\xff"
    end

    it "Time -(1 << 23)s 999_999_999ns" do
      obj = Time.at(-(1 << 23) + Rational(1) - Rational(1, 1_000_000_000)).utc
      match obj, "\xd7\xfe\xcb\x80\x00\x00\x3b\x9a\xc9\xff"
    end

    it "Time -(1 << 31)s 999_999_999ns" do
      obj = Time.at(-(1 << 31) + Rational(1) - Rational(1, 1_000_000_000)).utc
      match obj, "\xc7\x09\xfe\xcf\x80\x00\x00\x00\x3b\x9a\xc9\xff"
    end

    it "Time -(1 << 39)s 999_999_999ns" do
      obj = Time.at(-(1 << 39) + Rational(1) - Rational(1, 1_000_000_000)).utc
      match obj, "\xc7\x0a\xfe\xd3\x80\x00\x00\x00\x00\x3b\x9a\xc9\xff"
    end

    it "Time -(1 << 47)s 999_999_999ns" do
      obj = Time.at(-(1 << 47) + Rational(1) - Rational(1, 1_000_000_000)).utc
      match obj, "\xc7\x0b\xfe\xd7\x80\x00\x00\x00\x00\x00\x3b\x9a\xc9\xff"
    end

    it "Time -(1 << 55)s 999_999_999ns" do
      obj = Time.at(-(1 << 55) + Rational(1) - Rational(1, 1_000_000_000)).utc
      match obj, "\xc7\x0c\xfe\xdb\x80\x00\x00\x00\x00\x00\x00\x3b\x9a\xc9\xff"
    end

    it "Time -(1 << 63)s 999_999_999ns" do
      obj = Time.at(-(1 << 63) + Rational(1) - Rational(1, 1_000_000_000)).utc
      match obj, "\xc7\x0d\xfe\xdf\x80\x00\x00\x00\x00\x00\x00\x00\x3b\x9a\xc9\xff"
    end

    it "Time (1 << 7) - 1s 999_999_999ns" do
      obj = Time.at((1 << 7) + Rational(1) - Rational(1, 1_000_000_000) - 1).utc
      match obj, "\xc7\x06\xfe\xc3\x7f\x3b\x9a\xc9\xff"
    end

    it "Time (1 << 15) - 1s 999_999_999ns" do
      obj = Time.at((1 << 15) + Rational(1) - Rational(1, 1_000_000_000) - 1).utc
      match obj, "\xc7\x07\xfe\xc7\x7f\xff\x3b\x9a\xc9\xff"
    end

    it "Time (1 << 23) - 1s 999_999_999ns" do
      obj = Time.at((1 << 23) + Rational(1) - Rational(1, 1_000_000_000) - 1).utc
      match obj, "\xd7\xfe\xcb\x7f\xff\xff\x3b\x9a\xc9\xff"
    end

    it "Time (1 << 31) - 1s 999_999_999ns" do
      obj = Time.at((1 << 31) + Rational(1) - Rational(1, 1_000_000_000) - 1).utc
      match obj, "\xc7\x09\xfe\xcf\x7f\xff\xff\xff\x3b\x9a\xc9\xff"
    end

    it "Time (1 << 39) - 1s 999_999_999ns" do
      obj = Time.at((1 << 39) + Rational(1) - Rational(1, 1_000_000_000) - 1).utc
      match obj, "\xc7\x0a\xfe\xd3\x7f\xff\xff\xff\xff\x3b\x9a\xc9\xff"
    end

    it "Time (1 << 47) - 1s 999_999_999ns" do
      obj = Time.at((1 << 47) + Rational(1) - Rational(1, 1_000_000_000) - 1).utc
      match obj, "\xc7\x0b\xfe\xd7\x7f\xff\xff\xff\xff\xff\x3b\x9a\xc9\xff"
    end

    it "Time (1 << 55) - 1s 999_999_999ns" do
      obj = Time.at((1 << 55) + Rational(1) - Rational(1, 1_000_000_000) - 1).utc
      match obj, "\xc7\x0c\xfe\xdb\x7f\xff\xff\xff\xff\xff\xff\x3b\x9a\xc9\xff"
    end

    it "Time (1 << 63) - 1s 999_999_999ns" do
      obj = Time.at((1 << 63) + Rational(1) - Rational(1, 1_000_000_000) - 1).utc
      match obj, "\xc7\x0d\xfe\xdf\x7f\xff\xff\xff\xff\xff\xff\xff\x3b\x9a\xc9\xff"
    end

    # timezone stuffs
    it "Time Aug 11 1989 10:08PM +8:00" do
      obj = Time.new(2013, 8, 11, 22, 8, nil, "+08:00")
      match obj, "\xc7\x07\xfe\xac\x52\x07\x9a\xc0\x01\xe0"
    end

    it "Time Aug 11 1989 10:08PM -12:00" do
      obj = Time.new(2013, 8, 11, 2, 8, nil, "-12:00")
      match obj, "\xc7\x07\xfe\xac\x52\x07\x9a\xc0\x3d\x30"
    end

    it "-(1 << 1)" do
      obj = Time.new(2013, 8, 11, 14, 6, nil, "-00:02")
      match obj, "\xc7\x07\xfe\xac\x52\x07\x9a\xc0\x3f\xfe"
    end

    it "-(1 << 2)" do
      obj = Time.new(2013, 8, 11, 14, 4, nil, "-00:04")
      match obj, "\xc7\x07\xfe\xac\x52\x07\x9a\xc0\x3f\xfc"
    end

    it "-(1 << 3)" do
      obj = Time.new(2013, 8, 11, 14, 0, nil, "-00:08")
      match obj, "\xc7\x07\xfe\xac\x52\x07\x9a\xc0\x3f\xf8"
    end

    it "-(1 << 4)" do
      obj = Time.new(2013, 8, 11, 13, 52, nil, "-00:16")
      match obj, "\xc7\x07\xfe\xac\x52\x07\x9a\xc0\x3f\xf0"
    end

    it "-(1 << 5)" do
      obj = Time.new(2013, 8, 11, 13, 36, nil, "-00:32")
      match obj, "\xc7\x07\xfe\xac\x52\x07\x9a\xc0\x3f\xe0"
    end

    it "-(1 << 6)" do
      obj = Time.new(2013, 8, 11, 13, 4, nil, "-01:04")
      match obj, "\xc7\x07\xfe\xac\x52\x07\x9a\xc0\x3f\xc0"
    end

    it "-(1 << 7)" do
      obj = Time.new(2013, 8, 11, 12, 0, nil, "-02:08")
      match obj, "\xc7\x07\xfe\xac\x52\x07\x9a\xc0\x3f\x80"
    end

    it "-(1 << 8)" do
      obj = Time.new(2013, 8, 11, 9, 52, nil, "-04:16")
      match obj, "\xc7\x07\xfe\xac\x52\x07\x9a\xc0\x3f\x00"
    end

    it "-(1 << 9)" do
      obj = Time.new(2013, 8, 11, 5, 36, nil, "-08:32")
      match obj, "\xc7\x07\xfe\xac\x52\x07\x9a\xc0\x3e\x00"
    end

    it "-(1 << 10)" do
      obj = Time.new(2013, 8, 10, 21, 4, nil, "-17:04")
      match obj, "\xc7\x07\xfe\xac\x52\x07\x9a\xc0\x3c\x00"
    end

    it "-23:59 Minimum limit of Ruby" do
      obj = Time.new(2013, 8, 10, 14, 9, nil, "-23:59")
      match obj, "\xc7\x07\xfe\xac\x52\x07\x9a\xc0\x3a\x61"
    end

    it "(1 << 1) - 1" do
      obj = Time.new(2013, 8, 11, 14, 9, nil, "+00:01")
      match obj, "\xc7\x07\xfe\xac\x52\x07\x9a\xc0\x00\x01"
    end

    it "(1 << 2) - 1" do
      obj = Time.new(2013, 8, 11, 14, 11, nil, "+00:03")
      match obj, "\xc7\x07\xfe\xac\x52\x07\x9a\xc0\x00\x03"
    end

    it "(1 << 3) - 1" do
      obj = Time.new(2013, 8, 11, 14, 15, nil, "+00:07")
      match obj, "\xc7\x07\xfe\xac\x52\x07\x9a\xc0\x00\x07"
    end

    it "(1 << 4) - 1" do
      obj = Time.new(2013, 8, 11, 14, 23, nil, "+00:15")
      match obj, "\xc7\x07\xfe\xac\x52\x07\x9a\xc0\x00\x0f"
    end

    it "(1 << 5) - 1" do
      obj = Time.new(2013, 8, 11, 14, 39, nil, "+00:31")
      match obj, "\xc7\x07\xfe\xac\x52\x07\x9a\xc0\x00\x1f"
    end

    it "(1 << 6) - 1" do
      obj = Time.new(2013, 8, 11, 15, 13, nil, "+01:05")
      match obj, "\xc7\x07\xfe\xac\x52\x07\x9a\xc0\x00\x41"
    end

    it "(1 << 7) - 1" do
      obj = Time.new(2013, 8, 11, 16, 15, nil, "+02:07")
      match obj, "\xc7\x07\xfe\xac\x52\x07\x9a\xc0\x00\x7f"
    end

    it "(1 << 8) - 1" do
      obj = Time.new(2013, 8, 11, 18, 23, nil, "+04:15")
      match obj, "\xc7\x07\xfe\xac\x52\x07\x9a\xc0\x00\xff"
    end

    it "(1 << 9) - 1" do
      obj = Time.new(2013, 8, 11, 22, 40, nil, "+08:32")
      match obj, "\xc7\x07\xfe\xac\x52\x07\x9a\xc0\x02\x00"
    end

    it "(1 << 10) - 1" do
      obj = Time.new(2013, 8, 12, 7, 11, nil, "+17:03")
      match obj, "\xc7\x07\xfe\xac\x52\x07\x9a\xc0\x03\xff"
    end

    it "23:59 Maximum limit of Ruby" do
      obj = Time.new(2013, 8, 12, 14, 7, nil, "+23:59")
      match obj, "\xc7\x07\xfe\xac\x52\x07\x9a\xc0\x05\x9f"
    end

    # dst
    it "dst" do
      obj = with_tz("America/Los_Angeles") { Time.new(2013, 8, 11, 7, 8) }
      match obj, "\xc7\x07\xfe\xac\x52\x07\x9a\xc0\xfe\x5c"
    end

    it "positive dst" do
      obj = with_tz("Asia/Damascus") { Time.new(2013, 8, 11, 17, 8) }
      match obj, "\xc7\x07\xfe\xac\x52\x07\x9a\xc0\xc0\xb4"
    end

    # spec examples
    it "Jan 1, 1970" do
      obj = Time.gm(1970, 1, 1)
      match obj, "\xd4\xfe\x00"
    end

    it "Apr 1, 1970" do
      obj = Time.gm(1970, 4, 1)
      match obj, "\xd6\xfe\x88\x76\xa7\x00"
    end

    it "Jan 1, 2050 +200ns" do
      obj = Time.gm(2050, 1, 1, 0, 0, 0, 0.2)
      match obj, "\xc7\x07\xfe\xd0\x00\x96\x7a\x76\x00\xc8"
    end
  end

## FIXME
#  it "{0=>0, 1=>1, ..., 14=>14}" do
#    a = (0..14).to_a;
#    match Hash[*a.zip(a).flatten], "\x8f\x05\x05\x0b\x0b\x00\x00\x06\x06\x0c\x0c\x01\x01\x07\x07\x0d\x0d\x02\x02\x08\x08\x0e\x0e\x03\x03\x09\x09\x04\x04\x0a\x0a"
#  end
#
#  it "{0=>0, 1=>1, ..., 15=>15}" do
#    a = (0..15).to_a;
#    match Hash[*a.zip(a).flatten], "\xde\x00\x10\x05\x05\x0b\x0b\x00\x00\x06\x06\x0c\x0c\x01\x01\x07\x07\x0d\x0d\x02\x02\x08\x08\x0e\x0e\x03\x03\x09\x09\x0f\x0f\x04\x04\x0a\x0a"
#  end

## FIXME
#  it "fixmap" do
#    check_map 1, 0
#    check_map 1, (1<<4)-1
#  end
#
#  it "map 16" do
#    check_map 3, (1<<4)
#    check_map 3, (1<<16)-1
#  end
#
#  it "map 32" do
#    check_map 5, (1<<16)
#    #check_map 5, (1<<32)-1  # memory error
#  end

  def check(len, obj)
    raw = obj.to_msgpack.to_s
    raw.length.should == len
    MessagePack.unpack(raw).should == obj
  end

  def check_raw(overhead, num)
    check num+overhead, " "*num
  end

  def check_array(overhead, num)
    check num+overhead, Array.new(num)
  end

  def check_ext(overhead, num, type)
    check num+overhead, MessagePack::Extended.new(type, "a" * num)
  end

  def match(obj, buf)
    raw = obj.to_msgpack.to_s
    raw.should == buf
  end

  def with_tz(tz)
    if /linux/ =~ RUBY_PLATFORM || ENV["RUBY_FORCE_TIME_TZ_TEST"] == "yes"
      old = ENV["TZ"]
      begin
        ENV["TZ"] = tz
        yield
      ensure
        ENV["TZ"] = old
      end
    else
      if ENV["TZ"] == tz
        yield
      end
    end
  end
end

