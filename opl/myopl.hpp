/*
 * pyopl.cpp - Main OPL wrapper.
 *
 * Copyright (C) 2011-2012 Adam Nielsen <malvineous@shikadi.net>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#include <stdio.h>
#include <cassert>
#include "dbopl.h"

// Size of each sample in bytes (2 == 16-bit)
#define SAMPLE_SIZE 2

// Volume amplication (0 == none, 1 == 2x, 2 == 4x)
#define VOL_AMP 1

// Clipping function to prevent integer wraparound after amplification
#define SAMP_BITS (SAMPLE_SIZE << 3)
#define SAMP_MAX ((1 << (SAMP_BITS-1)) - 1)
#define SAMP_MIN -((1 << (SAMP_BITS-1)))
#define CLIP(v) (((v) > SAMP_MAX) ? SAMP_MAX : (((v) < SAMP_MIN) ? SAMP_MIN : (v)))

struct my_buffer {
public:
        unsigned char *buf;
        static const unsigned int len = 8192;
	my_buffer() { buf = new(unsigned char[len]); };
        ~my_buffer() { delete buf; }
};

class SampleHandler: public MixerChannel {
	public:
		my_buffer mybuf;
		uint8_t channels;

		SampleHandler(uint8_t channels)
			: channels(channels)
		{
		}

		virtual ~SampleHandler()
		{
		}

		virtual void AddSamples_m32(Bitu samples, Bit32s *buffer)
		{
			// Convert samples from mono s32 to stereo s16
			int16_t *out = (int16_t *)this->mybuf.buf;
			for (unsigned int i = 0; i < samples; i++) {
				Bit32s v = buffer[i] << VOL_AMP;
				*out++ = CLIP(v);
				if (channels == 2) *out++ = CLIP(v);
			}
			return;
		}

		virtual void AddSamples_s32(Bitu samples, Bit32s *buffer)
		{
			// Convert samples from stereo s32 to stereo s16
			int16_t *out = (int16_t *)this->mybuf.buf;
			for (unsigned int i = 0; i < samples; i++) {
				Bit32s v = buffer[i*2] << VOL_AMP;
				*out++ = CLIP(v);
				if (channels == 2) {
					v = buffer[i*2+1] << VOL_AMP;
					*out++ = CLIP(v);
				}
			}
			return;
		}
};

struct MyOPL {
private:
	// Can't put any objects in here (only pointers) as this struct is allocated
	// with malloc() instead of operator new (so constructors don't get called.)
	SampleHandler *sh;
	DBOPL::Handler *opl;
public:
        void opl_writeReg(int reg, int val) { this->opl->WriteReg(reg, val); }
        void opl_getSamples()
{
	int samples = this->sh->mybuf.len / SAMPLE_SIZE / this->sh->channels;
	if (samples > 512)
		perror("buffer too large (max 512 samples)");
	if (samples < 2)
		perror("buffer too small (min 2 samples)");

	this->opl->Generate(this->sh, samples);

	delete(&this->sh->mybuf); // won't use it any more
};

MyOPL(unsigned int freq=44100, uint8_t sampleSize=SAMPLE_SIZE, uint8_t channels=2)
{
	if (sampleSize != SAMPLE_SIZE) {
		perror("invalid sample size (valid values: 2=16-bit)");
	}
	if ((channels != 1) && (channels != 2)) {
		perror("invalid channel count (valid values: 1=mono, 2=stereo)");
	}

	this->sh = new SampleHandler(channels);
	this->opl = new DBOPL::Handler();
	this->opl->Init(freq);
};
};


