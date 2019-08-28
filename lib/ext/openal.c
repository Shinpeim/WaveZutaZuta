#include <stdint.h>
#include <stdio.h>

#include <ruby.h>
#include "narray.h"

#include <OpenAL/al.h>
#include <OpenAL/alc.h>

#define CHECK_AL_ERROR(msg) if (alGetError() != AL_NO_ERROR) { rb_raise(rb_eRuntimeError, (msg)); }

static VALUE cOpenAL;
static VALUE cOpenALBuffer;

typedef struct {
  ALCdevice *device;
  ALCcontext *context;
} alc_context_t;

typedef struct {
  ALuint  source;
  ALuint  buffer;
  ALshort *data;
} al_buffer_t;

void openal_free(alc_context_t *alc)
{
  alcMakeContextCurrent(NULL);
  CHECK_AL_ERROR("alcMakeContextCurrent(NULL); failed.")
  alcDestroyContext(alc->context);
  CHECK_AL_ERROR("failed to destroy context")
  alcCloseDevice(alc->device);
  CHECK_AL_ERROR("failed to close device")
}

static VALUE
openal_alloc(VALUE klass)
{
  alc_context_t *alc = ALLOC(alc_context_t);
  return Data_Wrap_Struct(klass, 0, openal_free, alc);
}

VALUE
openal_initialize(VALUE self)
{
  const ALCint attrlist[] = {ALC_SYNC, AL_TRUE, 0};

  alc_context_t *alc;
  Data_Get_Struct(self, alc_context_t, alc);

  alc->device  = alcOpenDevice(NULL);
  CHECK_AL_ERROR("failed to open device");
  alc->context = alcCreateContext(alc->device, NULL);
  CHECK_AL_ERROR("failed to open context");
  alcMakeContextCurrent(alc->context);
  CHECK_AL_ERROR("failed to set context");
  return Qnil;
}

VALUE
openal_create_buffer(VALUE self, VALUE channels, VALUE bitswidth, VALUE freq, VALUE data)
{
  return rb_funcall(cOpenALBuffer, rb_intern("new"), 4, channels, bitswidth, freq, data);
}


void openal_buffer_free(al_buffer_t *al_buffer)
{
  free(al_buffer->data);
  alDeleteSources(1, &(al_buffer->source));
  CHECK_AL_ERROR("failed to delete source");
  alDeleteBuffers(1, &(al_buffer->buffer));
  CHECK_AL_ERROR("failed to delete buffers");
}

static VALUE
openal_buffer_alloc(VALUE klass)
{
  al_buffer_t *al_buffer = ALLOC(al_buffer_t);
  return Data_Wrap_Struct(klass, 0, openal_buffer_free, al_buffer);
}

VALUE
openal_buffer_initialize(VALUE self, VALUE channelsVal, VALUE bitswidthVal, VALUE freqVal, VALUE data)
{
  al_buffer_t *al_buffer;
  int rank;
  int frames;
  uint8_t *buf_8bit;
  int16_t *buf_16bit;

  int channels, bitswidth, freq;

  Data_Get_Struct(self, al_buffer_t, al_buffer);

  channels  = NUM2INT(channelsVal);
  bitswidth = NUM2INT(bitswidthVal);
  freq      = NUM2INT(freqVal);

  if (bitswidth == 8) {
    data = na_cast_object(data, NA_BYTE);
    buf_8bit = NA_PTR_TYPE(data, uint8_t *);
  }
  else if (bitswidth == 16) {
    data = na_cast_object(data, NA_SINT);
    buf_16bit = NA_PTR_TYPE(data, int16_t *);
  }
  else {
    rb_raise(rb_eArgError, "bitswidth must be 8 or 16");
  }

  if (channels > 2)
    rb_raise(rb_eArgError, "channels must be 1 or 2.");

  rank = NA_RANK(data);
  if (rank > 1)
    rb_raise(rb_eArgError, "buffer narray rank must be 1.");

  alGenBuffers(1, &al_buffer->buffer);
  CHECK_AL_ERROR("failed to gen buffer");

  frames = NA_SHAPE0(data);
  if (bitswidth == 8) {
    al_buffer->data = malloc(sizeof(ALshort) * frames);
    for (int i = 0; i < frames; i++) {
      al_buffer->data[i] = buf_8bit[i];
    }
  }
  else {
    al_buffer->data = malloc(sizeof(ALshort) * frames);
    for (int i = 0; i < frames; i++) {
      al_buffer->data[i] = buf_16bit[i];
    }
  }

  if (channels == 1 && bitswidth == 8) {
    alBufferData(al_buffer->buffer, AL_FORMAT_MONO8, al_buffer->data, sizeof(ALshort) * frames, freq);
    CHECK_AL_ERROR("failed to set buffer");
  }
  else if (channels == 2 && bitswidth == 8) {
    alBufferData(al_buffer->buffer, AL_FORMAT_STEREO8, al_buffer->data, sizeof(ALshort) * frames, freq);
    CHECK_AL_ERROR("failed to set buffer");
  }
  else if (channels == 1 && bitswidth == 16) {
    alBufferData(al_buffer->buffer, AL_FORMAT_MONO16, al_buffer->data, sizeof(ALshort) * frames, freq);
    CHECK_AL_ERROR("failed to set buffer");
  }
  else if (channels == 2 && bitswidth == 16) {
    alBufferData(al_buffer->buffer, AL_FORMAT_STEREO16, al_buffer->data, sizeof(ALshort) * frames, freq);
    CHECK_AL_ERROR("failed to set buffer");
  }

  alGenSources(1, &al_buffer->source);
  CHECK_AL_ERROR("failed to gen source");

  alSourcei(al_buffer->source, AL_BUFFER, al_buffer->buffer);
  CHECK_AL_ERROR("failed to set buffer to source");

  return Qnil;
}

VALUE
openal_buffer_play(VALUE self)
{
  al_buffer_t *al_buffer;
  ALint state;
  Data_Get_Struct(self, al_buffer_t, al_buffer);

  alSourcePlay(al_buffer->source);
  CHECK_AL_ERROR("failed to play source");

  return Qnil;
}

void
Init_openal()
{
  cOpenAL = rb_define_class("OpenAL", rb_cObject);
  rb_define_alloc_func(cOpenAL, openal_alloc);
  rb_define_method(cOpenAL, "initialize", openal_initialize, 0);
  rb_define_method(cOpenAL, "create_buffer", openal_create_buffer, 4);

  cOpenALBuffer = rb_define_class_under(cOpenAL, "Buffer", rb_cObject);
  rb_define_alloc_func(cOpenALBuffer, openal_buffer_alloc);
  rb_define_method(cOpenALBuffer, "initialize", openal_buffer_initialize, 4);
  rb_define_method(cOpenALBuffer, "play", openal_buffer_play, 0);
}
