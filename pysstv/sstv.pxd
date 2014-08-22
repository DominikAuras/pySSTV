  
cdef class SSTV:
  
    cdef public object image
    cdef int samples_per_sec
    cdef int bits
    cdef public int vox_enabled
    cdef str fskid_payload
    cdef int nchannels
    cdef public object pixels
    
    
    cpdef on_init(self)
    cpdef write_wav(self, filename)
    cpdef gen_samples(self)
    cpdef gen_values(self)
    cpdef gen_freq_bits(self)
    cpdef horizontal_sync(self)