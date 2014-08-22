#!/usr/bin/env python

from __future__ import division, with_statement
from math import sin, pi
from random import random
from contextlib import closing
from itertools import imap, izip, cycle, chain
from array import array
import wave

FREQ_VIS_BIT1 = 1100
FREQ_SYNC = 1200
FREQ_VIS_BIT0 = 1300
FREQ_BLACK = 1500
FREQ_VIS_START = 1900
FREQ_WHITE = 2300
FREQ_RANGE = FREQ_WHITE - FREQ_BLACK
FREQ_FSKID_BIT1 = 1900
FREQ_FSKID_BIT0 = 2100

MSEC_VIS_START = 300
MSEC_VIS_SYNC = 10
MSEC_VIS_BIT = 30
MSEC_FSKID_BIT = 22

cdef class SSTV:
  
    def __init__(self, image, samples_per_sec, bits):
        self.image = image
        self.samples_per_sec = samples_per_sec
        self.bits = bits
        self.vox_enabled = False
        self.fskid_payload = ''
        self.nchannels = 1
        self.on_init()

    cpdef on_init(self):
        pass

    BITS_TO_STRUCT = {8: 'b', 16: 'h'}

    cpdef write_wav(self, filename):
        """writes the whole image to a Microsoft WAV file"""
        fmt = self.BITS_TO_STRUCT[self.bits]
        data = array(fmt, self.gen_samples())
        if self.nchannels != 1:
            data = array(fmt, chain.from_iterable(
                izip(*([data] * self.nchannels))))
        with closing(wave.open(filename, 'wb')) as wav:
            wav.setnchannels(self.nchannels)
            wav.setsampwidth(self.bits // 8)
            wav.setframerate(self.samples_per_sec)
            wav.writeframes(data.tostring())

    cpdef gen_samples(self):
        """generates discrete samples from gen_values()

           performs quantization according to
           the bits per sample value given during construction
        """
        cdef list ret = []
        cdef double alias, value, alias_item
        cdef int max_value, amp, lowest, highest, sample
        
        max_value = 2 ** self.bits
        alias = 1 / max_value
        amp = max_value // 2
        lowest = -amp
        highest = amp - 1
        alias_cycle = cycle([alias * (random() - 0.5) for _ in range(1024)])
        for value, alias_item in izip(self.gen_values(), alias_cycle):
            sample = int(value * amp + alias_item)
            if sample <= lowest:
              ret.append(lowest)
            elif sample <= highest:
              ret.append(sample)
            else:
              ret.append(highest)
        return ret

    cpdef gen_values(self):
        """generates samples between -1 and +1 from gen_freq_bits()

           performs sampling according to
           the samples per second value given during construction
        """
        cdef list ret = []
        cdef double spms, offset, factor, samples, freq_factor, freq, msec
        cdef int tx, sample
        
        spms = self.samples_per_sec / 1000.
        offset = 0
        samples = 0
        factor = 2 * pi / self.samples_per_sec
        sample = 0
        for freq, msec in self.gen_freq_bits():
            samples += spms * msec
            tx = int(samples)
            freq_factor = freq * factor
            ret += [sin(sample * freq_factor + offset) for sample in range(tx)]
            offset += (sample + 1) * freq_factor
            samples -= tx
        return ret

    cpdef gen_freq_bits(self):
        """generates tuples (freq, msec) that describe a sine wave segment

           frequency "freq" in Hz and duration "msec" in ms
        """
        cdef list ret = []
        cdef int vis, num_ones, bit, fskid_byte        
        cdef double bit_freq, parity_freq, freq
        
        if self.vox_enabled:
            for freq in (1900, 1500, 1900, 1500, 2300, 1500, 2300, 1500):
                ret.append((freq, 100))
        ret += [(FREQ_VIS_START, MSEC_VIS_START),
                (FREQ_SYNC, MSEC_VIS_SYNC),
                (FREQ_VIS_START, MSEC_VIS_START),
                (FREQ_SYNC, MSEC_VIS_BIT)]  # start bit
        vis = self.VIS_CODE
        num_ones = 0
        for _ in xrange(7):
            bit = vis & 1
            vis >>= 1
            num_ones += bit
            bit_freq = FREQ_VIS_BIT1 if bit == 1 else FREQ_VIS_BIT0
            ret.append((bit_freq, MSEC_VIS_BIT))
        parity_freq = FREQ_VIS_BIT1 if num_ones % 2 == 1 else FREQ_VIS_BIT0
        ret += [(parity_freq, MSEC_VIS_BIT),
                (FREQ_SYNC, MSEC_VIS_BIT)]  # stop bit
        ret += self.gen_image_tuples()
        for fskid_byte in imap(ord, self.fskid_payload):
            for _ in xrange(6):
                bit = fskid_byte & 1
                fskid_byte >>= 1
                bit_freq = FREQ_FSKID_BIT1 if bit == 1 else FREQ_FSKID_BIT0
                ret.append((bit_freq, MSEC_FSKID_BIT))
        return ret

    def gen_image_tuples(self):
        return []

    def add_fskid_text(self, text):
        self.fskid_payload += '\x20\x2a{0}\x01'.format(
                ''.join(chr(ord(c) - 0x20) for c in text))

    cpdef horizontal_sync(self):
        return [(FREQ_SYNC, self.SYNC)]


cpdef byte_to_freq(value):
    return FREQ_BLACK + FREQ_RANGE * value / 255
