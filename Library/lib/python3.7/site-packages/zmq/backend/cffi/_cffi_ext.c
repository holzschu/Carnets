
#include <Python.h>
#include <stddef.h>

/* this block of #ifs should be kept exactly identical between
   c/_cffi_backend.c, cffi/vengine_cpy.py, cffi/vengine_gen.py
   and cffi/_cffi_include.h */
#if defined(_MSC_VER)
# include <malloc.h>   /* for alloca() */
# if _MSC_VER < 1600   /* MSVC < 2010 */
   typedef __int8 int8_t;
   typedef __int16 int16_t;
   typedef __int32 int32_t;
   typedef __int64 int64_t;
   typedef unsigned __int8 uint8_t;
   typedef unsigned __int16 uint16_t;
   typedef unsigned __int32 uint32_t;
   typedef unsigned __int64 uint64_t;
   typedef __int8 int_least8_t;
   typedef __int16 int_least16_t;
   typedef __int32 int_least32_t;
   typedef __int64 int_least64_t;
   typedef unsigned __int8 uint_least8_t;
   typedef unsigned __int16 uint_least16_t;
   typedef unsigned __int32 uint_least32_t;
   typedef unsigned __int64 uint_least64_t;
   typedef __int8 int_fast8_t;
   typedef __int16 int_fast16_t;
   typedef __int32 int_fast32_t;
   typedef __int64 int_fast64_t;
   typedef unsigned __int8 uint_fast8_t;
   typedef unsigned __int16 uint_fast16_t;
   typedef unsigned __int32 uint_fast32_t;
   typedef unsigned __int64 uint_fast64_t;
   typedef __int64 intmax_t;
   typedef unsigned __int64 uintmax_t;
# else
#  include <stdint.h>
# endif
# if _MSC_VER < 1800   /* MSVC < 2013 */
#  ifndef __cplusplus
    typedef unsigned char _Bool;
#  endif
# endif
#else
# include <stdint.h>
# if (defined (__SVR4) && defined (__sun)) || defined(_AIX) || defined(__hpux)
#  include <alloca.h>
# endif
#endif

#if PY_MAJOR_VERSION < 3
# undef PyCapsule_CheckExact
# undef PyCapsule_GetPointer
# define PyCapsule_CheckExact(capsule) (PyCObject_Check(capsule))
# define PyCapsule_GetPointer(capsule, name) \
    (PyCObject_AsVoidPtr(capsule))
#endif

#if PY_MAJOR_VERSION >= 3
# define PyInt_FromLong PyLong_FromLong
#endif

#define _cffi_from_c_double PyFloat_FromDouble
#define _cffi_from_c_float PyFloat_FromDouble
#define _cffi_from_c_long PyInt_FromLong
#define _cffi_from_c_ulong PyLong_FromUnsignedLong
#define _cffi_from_c_longlong PyLong_FromLongLong
#define _cffi_from_c_ulonglong PyLong_FromUnsignedLongLong
#define _cffi_from_c__Bool PyBool_FromLong

#define _cffi_to_c_double PyFloat_AsDouble
#define _cffi_to_c_float PyFloat_AsDouble

#define _cffi_from_c_int_const(x)                                        \
    (((x) > 0) ?                                                         \
        ((unsigned long long)(x) <= (unsigned long long)LONG_MAX) ?      \
            PyInt_FromLong((long)(x)) :                                  \
            PyLong_FromUnsignedLongLong((unsigned long long)(x)) :       \
        ((long long)(x) >= (long long)LONG_MIN) ?                        \
            PyInt_FromLong((long)(x)) :                                  \
            PyLong_FromLongLong((long long)(x)))

#define _cffi_from_c_int(x, type)                                        \
    (((type)-1) > 0 ? /* unsigned */                                     \
        (sizeof(type) < sizeof(long) ?                                   \
            PyInt_FromLong((long)x) :                                    \
         sizeof(type) == sizeof(long) ?                                  \
            PyLong_FromUnsignedLong((unsigned long)x) :                  \
            PyLong_FromUnsignedLongLong((unsigned long long)x)) :        \
        (sizeof(type) <= sizeof(long) ?                                  \
            PyInt_FromLong((long)x) :                                    \
            PyLong_FromLongLong((long long)x)))

#define _cffi_to_c_int(o, type)                                          \
    ((type)(                                                             \
     sizeof(type) == 1 ? (((type)-1) > 0 ? (type)_cffi_to_c_u8(o)        \
                                         : (type)_cffi_to_c_i8(o)) :     \
     sizeof(type) == 2 ? (((type)-1) > 0 ? (type)_cffi_to_c_u16(o)       \
                                         : (type)_cffi_to_c_i16(o)) :    \
     sizeof(type) == 4 ? (((type)-1) > 0 ? (type)_cffi_to_c_u32(o)       \
                                         : (type)_cffi_to_c_i32(o)) :    \
     sizeof(type) == 8 ? (((type)-1) > 0 ? (type)_cffi_to_c_u64(o)       \
                                         : (type)_cffi_to_c_i64(o)) :    \
     (Py_FatalError("unsupported size for type " #type), (type)0)))

#define _cffi_to_c_i8                                                    \
                 ((int(*)(PyObject *))_cffi_exports[1])
#define _cffi_to_c_u8                                                    \
                 ((int(*)(PyObject *))_cffi_exports[2])
#define _cffi_to_c_i16                                                   \
                 ((int(*)(PyObject *))_cffi_exports[3])
#define _cffi_to_c_u16                                                   \
                 ((int(*)(PyObject *))_cffi_exports[4])
#define _cffi_to_c_i32                                                   \
                 ((int(*)(PyObject *))_cffi_exports[5])
#define _cffi_to_c_u32                                                   \
                 ((unsigned int(*)(PyObject *))_cffi_exports[6])
#define _cffi_to_c_i64                                                   \
                 ((long long(*)(PyObject *))_cffi_exports[7])
#define _cffi_to_c_u64                                                   \
                 ((unsigned long long(*)(PyObject *))_cffi_exports[8])
#define _cffi_to_c_char                                                  \
                 ((int(*)(PyObject *))_cffi_exports[9])
#define _cffi_from_c_pointer                                             \
    ((PyObject *(*)(char *, CTypeDescrObject *))_cffi_exports[10])
#define _cffi_to_c_pointer                                               \
    ((char *(*)(PyObject *, CTypeDescrObject *))_cffi_exports[11])
#define _cffi_get_struct_layout                                          \
    ((PyObject *(*)(Py_ssize_t[]))_cffi_exports[12])
#define _cffi_restore_errno                                              \
    ((void(*)(void))_cffi_exports[13])
#define _cffi_save_errno                                                 \
    ((void(*)(void))_cffi_exports[14])
#define _cffi_from_c_char                                                \
    ((PyObject *(*)(char))_cffi_exports[15])
#define _cffi_from_c_deref                                               \
    ((PyObject *(*)(char *, CTypeDescrObject *))_cffi_exports[16])
#define _cffi_to_c                                                       \
    ((int(*)(char *, CTypeDescrObject *, PyObject *))_cffi_exports[17])
#define _cffi_from_c_struct                                              \
    ((PyObject *(*)(char *, CTypeDescrObject *))_cffi_exports[18])
#define _cffi_to_c_wchar_t                                               \
    ((wchar_t(*)(PyObject *))_cffi_exports[19])
#define _cffi_from_c_wchar_t                                             \
    ((PyObject *(*)(wchar_t))_cffi_exports[20])
#define _cffi_to_c_long_double                                           \
    ((long double(*)(PyObject *))_cffi_exports[21])
#define _cffi_to_c__Bool                                                 \
    ((_Bool(*)(PyObject *))_cffi_exports[22])
#define _cffi_prepare_pointer_call_argument                              \
    ((Py_ssize_t(*)(CTypeDescrObject *, PyObject *, char **))_cffi_exports[23])
#define _cffi_convert_array_from_object                                  \
    ((int(*)(char *, CTypeDescrObject *, PyObject *))_cffi_exports[24])
#define _CFFI_NUM_EXPORTS 25

typedef struct _ctypedescr CTypeDescrObject;

static void *_cffi_exports[_CFFI_NUM_EXPORTS];
static PyObject *_cffi_types, *_cffi_VerificationError;

static int _cffi_setup_custom(PyObject *lib);   /* forward */

static PyObject *_cffi_setup(PyObject *self, PyObject *args)
{
    PyObject *library;
    int was_alive = (_cffi_types != NULL);
    (void)self; /* unused */
    if (!PyArg_ParseTuple(args, "OOO", &_cffi_types, &_cffi_VerificationError,
                                       &library))
        return NULL;
    Py_INCREF(_cffi_types);
    Py_INCREF(_cffi_VerificationError);
    if (_cffi_setup_custom(library) < 0)
        return NULL;
    return PyBool_FromLong(was_alive);
}

static int _cffi_init(void)
{
    PyObject *module, *c_api_object = NULL;

    module = PyImport_ImportModule("_cffi_backend");
    if (module == NULL)
        goto failure;

    c_api_object = PyObject_GetAttrString(module, "_C_API");
    if (c_api_object == NULL)
        goto failure;
    if (!PyCapsule_CheckExact(c_api_object)) {
        PyErr_SetNone(PyExc_ImportError);
        goto failure;
    }
    memcpy(_cffi_exports, PyCapsule_GetPointer(c_api_object, "cffi"),
           _CFFI_NUM_EXPORTS * sizeof(void *));

    Py_DECREF(module);
    Py_DECREF(c_api_object);
    return 0;

  failure:
    Py_XDECREF(module);
    Py_XDECREF(c_api_object);
    return -1;
}

#define _cffi_type(num) ((CTypeDescrObject *)PyList_GET_ITEM(_cffi_types, num))

/**********/


#include <stdio.h>
#include <sys/un.h>
#include <string.h>

#include <zmq.h>
#include "zmq_compat.h"



static void _cffi_check__zmq_msg_t(zmq_msg_t *p)
{
  /* only to generate compile-time warnings or errors */
  (void)p;
}
static PyObject *
_cffi_layout__zmq_msg_t(PyObject *self, PyObject *noarg)
{
  struct _cffi_aligncheck { char x; zmq_msg_t y; };
  static Py_ssize_t nums[] = {
    sizeof(zmq_msg_t),
    offsetof(struct _cffi_aligncheck, y),
    -1
  };
  (void)self; /* unused */
  (void)noarg; /* unused */
  return _cffi_get_struct_layout(nums);
  /* the next line is not executed, but compiled */
  _cffi_check__zmq_msg_t(0);
}

static void _cffi_check__zmq_pollitem_t(zmq_pollitem_t *p)
{
  /* only to generate compile-time warnings or errors */
  (void)p;
  { void * *tmp = &p->socket; (void)tmp; }
  (void)((p->fd) << 1);
  (void)((p->events) << 1);
  (void)((p->revents) << 1);
}
static PyObject *
_cffi_layout__zmq_pollitem_t(PyObject *self, PyObject *noarg)
{
  struct _cffi_aligncheck { char x; zmq_pollitem_t y; };
  static Py_ssize_t nums[] = {
    sizeof(zmq_pollitem_t),
    offsetof(struct _cffi_aligncheck, y),
    offsetof(zmq_pollitem_t, socket),
    sizeof(((zmq_pollitem_t *)0)->socket),
    offsetof(zmq_pollitem_t, fd),
    sizeof(((zmq_pollitem_t *)0)->fd),
    offsetof(zmq_pollitem_t, events),
    sizeof(((zmq_pollitem_t *)0)->events),
    offsetof(zmq_pollitem_t, revents),
    sizeof(((zmq_pollitem_t *)0)->revents),
    -1
  };
  (void)self; /* unused */
  (void)noarg; /* unused */
  return _cffi_get_struct_layout(nums);
  /* the next line is not executed, but compiled */
  _cffi_check__zmq_pollitem_t(0);
}

int get_ipc_path_max_len(void) {
    struct sockaddr_un *dummy;
    return sizeof(dummy->sun_path) - 1;
}

static PyObject *
_cffi_f_get_ipc_path_max_len(PyObject *self, PyObject *noarg)
{
  int result;

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = get_ipc_path_max_len(); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  (void)noarg; /* unused */
  return _cffi_from_c_int(result, int);
}

static PyObject *
_cffi_f_memcpy(PyObject *self, PyObject *args)
{
  void * x0;
  void const * x1;
  size_t x2;
  Py_ssize_t datasize;
  void * result;
  PyObject *arg0;
  PyObject *arg1;
  PyObject *arg2;

  if (!PyArg_ParseTuple(args, "OOO:memcpy", &arg0, &arg1, &arg2))
    return NULL;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(0), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(0), arg0) < 0)
      return NULL;
  }

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(1), arg1, (char **)&x1);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x1 = alloca((size_t)datasize);
    memset((void *)x1, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x1, _cffi_type(1), arg1) < 0)
      return NULL;
  }

  x2 = _cffi_to_c_int(arg2, size_t);
  if (x2 == (size_t)-1 && PyErr_Occurred())
    return NULL;

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = memcpy(x0, x1, x2); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_pointer((char *)result, _cffi_type(0));
}

static PyObject *
_cffi_f_zmq_bind(PyObject *self, PyObject *args)
{
  void * x0;
  char const * x1;
  Py_ssize_t datasize;
  int result;
  PyObject *arg0;
  PyObject *arg1;

  if (!PyArg_ParseTuple(args, "OO:zmq_bind", &arg0, &arg1))
    return NULL;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(0), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(0), arg0) < 0)
      return NULL;
  }

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(2), arg1, (char **)&x1);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x1 = alloca((size_t)datasize);
    memset((void *)x1, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x1, _cffi_type(2), arg1) < 0)
      return NULL;
  }

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_bind(x0, x1); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_int(result, int);
}

static PyObject *
_cffi_f_zmq_close(PyObject *self, PyObject *arg0)
{
  void * x0;
  Py_ssize_t datasize;
  int result;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(0), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(0), arg0) < 0)
      return NULL;
  }

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_close(x0); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_int(result, int);
}

static PyObject *
_cffi_f_zmq_connect(PyObject *self, PyObject *args)
{
  void * x0;
  char const * x1;
  Py_ssize_t datasize;
  int result;
  PyObject *arg0;
  PyObject *arg1;

  if (!PyArg_ParseTuple(args, "OO:zmq_connect", &arg0, &arg1))
    return NULL;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(0), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(0), arg0) < 0)
      return NULL;
  }

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(2), arg1, (char **)&x1);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x1 = alloca((size_t)datasize);
    memset((void *)x1, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x1, _cffi_type(2), arg1) < 0)
      return NULL;
  }

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_connect(x0, x1); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_int(result, int);
}

static PyObject *
_cffi_f_zmq_ctx_destroy(PyObject *self, PyObject *arg0)
{
  void * x0;
  Py_ssize_t datasize;
  int result;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(0), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(0), arg0) < 0)
      return NULL;
  }

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_ctx_destroy(x0); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_int(result, int);
}

static PyObject *
_cffi_f_zmq_ctx_get(PyObject *self, PyObject *args)
{
  void * x0;
  int x1;
  Py_ssize_t datasize;
  int result;
  PyObject *arg0;
  PyObject *arg1;

  if (!PyArg_ParseTuple(args, "OO:zmq_ctx_get", &arg0, &arg1))
    return NULL;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(0), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(0), arg0) < 0)
      return NULL;
  }

  x1 = _cffi_to_c_int(arg1, int);
  if (x1 == (int)-1 && PyErr_Occurred())
    return NULL;

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_ctx_get(x0, x1); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_int(result, int);
}

static PyObject *
_cffi_f_zmq_ctx_new(PyObject *self, PyObject *noarg)
{
  void * result;

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_ctx_new(); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  (void)noarg; /* unused */
  return _cffi_from_c_pointer((char *)result, _cffi_type(0));
}

static PyObject *
_cffi_f_zmq_ctx_set(PyObject *self, PyObject *args)
{
  void * x0;
  int x1;
  int x2;
  Py_ssize_t datasize;
  int result;
  PyObject *arg0;
  PyObject *arg1;
  PyObject *arg2;

  if (!PyArg_ParseTuple(args, "OOO:zmq_ctx_set", &arg0, &arg1, &arg2))
    return NULL;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(0), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(0), arg0) < 0)
      return NULL;
  }

  x1 = _cffi_to_c_int(arg1, int);
  if (x1 == (int)-1 && PyErr_Occurred())
    return NULL;

  x2 = _cffi_to_c_int(arg2, int);
  if (x2 == (int)-1 && PyErr_Occurred())
    return NULL;

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_ctx_set(x0, x1, x2); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_int(result, int);
}

static PyObject *
_cffi_f_zmq_curve_keypair(PyObject *self, PyObject *args)
{
  char * x0;
  char * x1;
  Py_ssize_t datasize;
  int result;
  PyObject *arg0;
  PyObject *arg1;

  if (!PyArg_ParseTuple(args, "OO:zmq_curve_keypair", &arg0, &arg1))
    return NULL;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(3), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(3), arg0) < 0)
      return NULL;
  }

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(3), arg1, (char **)&x1);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x1 = alloca((size_t)datasize);
    memset((void *)x1, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x1, _cffi_type(3), arg1) < 0)
      return NULL;
  }

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_curve_keypair(x0, x1); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_int(result, int);
}

static PyObject *
_cffi_f_zmq_curve_public(PyObject *self, PyObject *args)
{
  char * x0;
  char * x1;
  Py_ssize_t datasize;
  int result;
  PyObject *arg0;
  PyObject *arg1;

  if (!PyArg_ParseTuple(args, "OO:zmq_curve_public", &arg0, &arg1))
    return NULL;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(3), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(3), arg0) < 0)
      return NULL;
  }

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(3), arg1, (char **)&x1);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x1 = alloca((size_t)datasize);
    memset((void *)x1, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x1, _cffi_type(3), arg1) < 0)
      return NULL;
  }

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_curve_public(x0, x1); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_int(result, int);
}

static PyObject *
_cffi_f_zmq_device(PyObject *self, PyObject *args)
{
  int x0;
  void * x1;
  void * x2;
  Py_ssize_t datasize;
  int result;
  PyObject *arg0;
  PyObject *arg1;
  PyObject *arg2;

  if (!PyArg_ParseTuple(args, "OOO:zmq_device", &arg0, &arg1, &arg2))
    return NULL;

  x0 = _cffi_to_c_int(arg0, int);
  if (x0 == (int)-1 && PyErr_Occurred())
    return NULL;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(0), arg1, (char **)&x1);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x1 = alloca((size_t)datasize);
    memset((void *)x1, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x1, _cffi_type(0), arg1) < 0)
      return NULL;
  }

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(0), arg2, (char **)&x2);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x2 = alloca((size_t)datasize);
    memset((void *)x2, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x2, _cffi_type(0), arg2) < 0)
      return NULL;
  }

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_device(x0, x1, x2); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_int(result, int);
}

static PyObject *
_cffi_f_zmq_disconnect(PyObject *self, PyObject *args)
{
  void * x0;
  char const * x1;
  Py_ssize_t datasize;
  int result;
  PyObject *arg0;
  PyObject *arg1;

  if (!PyArg_ParseTuple(args, "OO:zmq_disconnect", &arg0, &arg1))
    return NULL;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(0), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(0), arg0) < 0)
      return NULL;
  }

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(2), arg1, (char **)&x1);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x1 = alloca((size_t)datasize);
    memset((void *)x1, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x1, _cffi_type(2), arg1) < 0)
      return NULL;
  }

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_disconnect(x0, x1); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_int(result, int);
}

static PyObject *
_cffi_f_zmq_errno(PyObject *self, PyObject *noarg)
{
  int result;

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_errno(); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  (void)noarg; /* unused */
  return _cffi_from_c_int(result, int);
}

static PyObject *
_cffi_f_zmq_getsockopt(PyObject *self, PyObject *args)
{
  void * x0;
  int x1;
  void * x2;
  size_t * x3;
  Py_ssize_t datasize;
  int result;
  PyObject *arg0;
  PyObject *arg1;
  PyObject *arg2;
  PyObject *arg3;

  if (!PyArg_ParseTuple(args, "OOOO:zmq_getsockopt", &arg0, &arg1, &arg2, &arg3))
    return NULL;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(0), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(0), arg0) < 0)
      return NULL;
  }

  x1 = _cffi_to_c_int(arg1, int);
  if (x1 == (int)-1 && PyErr_Occurred())
    return NULL;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(0), arg2, (char **)&x2);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x2 = alloca((size_t)datasize);
    memset((void *)x2, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x2, _cffi_type(0), arg2) < 0)
      return NULL;
  }

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(4), arg3, (char **)&x3);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x3 = alloca((size_t)datasize);
    memset((void *)x3, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x3, _cffi_type(4), arg3) < 0)
      return NULL;
  }

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_getsockopt(x0, x1, x2, x3); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_int(result, int);
}

static PyObject *
_cffi_f_zmq_has(PyObject *self, PyObject *arg0)
{
  char const * x0;
  Py_ssize_t datasize;
  int result;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(2), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(2), arg0) < 0)
      return NULL;
  }

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_has(x0); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_int(result, int);
}

static PyObject *
_cffi_f_zmq_msg_close(PyObject *self, PyObject *arg0)
{
  zmq_msg_t * x0;
  Py_ssize_t datasize;
  int result;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(5), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(5), arg0) < 0)
      return NULL;
  }

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_msg_close(x0); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_int(result, int);
}

static PyObject *
_cffi_f_zmq_msg_data(PyObject *self, PyObject *arg0)
{
  zmq_msg_t * x0;
  Py_ssize_t datasize;
  void * result;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(5), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(5), arg0) < 0)
      return NULL;
  }

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_msg_data(x0); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_pointer((char *)result, _cffi_type(0));
}

static PyObject *
_cffi_f_zmq_msg_init(PyObject *self, PyObject *arg0)
{
  zmq_msg_t * x0;
  Py_ssize_t datasize;
  int result;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(5), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(5), arg0) < 0)
      return NULL;
  }

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_msg_init(x0); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_int(result, int);
}

static PyObject *
_cffi_f_zmq_msg_init_data(PyObject *self, PyObject *args)
{
  zmq_msg_t * x0;
  void * x1;
  size_t x2;
  zmq_free_fn * x3;
  void * x4;
  Py_ssize_t datasize;
  int result;
  PyObject *arg0;
  PyObject *arg1;
  PyObject *arg2;
  PyObject *arg3;
  PyObject *arg4;

  if (!PyArg_ParseTuple(args, "OOOOO:zmq_msg_init_data", &arg0, &arg1, &arg2, &arg3, &arg4))
    return NULL;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(5), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(5), arg0) < 0)
      return NULL;
  }

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(0), arg1, (char **)&x1);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x1 = alloca((size_t)datasize);
    memset((void *)x1, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x1, _cffi_type(0), arg1) < 0)
      return NULL;
  }

  x2 = _cffi_to_c_int(arg2, size_t);
  if (x2 == (size_t)-1 && PyErr_Occurred())
    return NULL;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(6), arg3, (char **)&x3);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x3 = alloca((size_t)datasize);
    memset((void *)x3, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x3, _cffi_type(6), arg3) < 0)
      return NULL;
  }

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(0), arg4, (char **)&x4);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x4 = alloca((size_t)datasize);
    memset((void *)x4, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x4, _cffi_type(0), arg4) < 0)
      return NULL;
  }

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_msg_init_data(x0, x1, x2, x3, x4); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_int(result, int);
}

static PyObject *
_cffi_f_zmq_msg_init_size(PyObject *self, PyObject *args)
{
  zmq_msg_t * x0;
  size_t x1;
  Py_ssize_t datasize;
  int result;
  PyObject *arg0;
  PyObject *arg1;

  if (!PyArg_ParseTuple(args, "OO:zmq_msg_init_size", &arg0, &arg1))
    return NULL;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(5), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(5), arg0) < 0)
      return NULL;
  }

  x1 = _cffi_to_c_int(arg1, size_t);
  if (x1 == (size_t)-1 && PyErr_Occurred())
    return NULL;

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_msg_init_size(x0, x1); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_int(result, int);
}

static PyObject *
_cffi_f_zmq_msg_recv(PyObject *self, PyObject *args)
{
  zmq_msg_t * x0;
  void * x1;
  int x2;
  Py_ssize_t datasize;
  int result;
  PyObject *arg0;
  PyObject *arg1;
  PyObject *arg2;

  if (!PyArg_ParseTuple(args, "OOO:zmq_msg_recv", &arg0, &arg1, &arg2))
    return NULL;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(5), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(5), arg0) < 0)
      return NULL;
  }

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(0), arg1, (char **)&x1);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x1 = alloca((size_t)datasize);
    memset((void *)x1, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x1, _cffi_type(0), arg1) < 0)
      return NULL;
  }

  x2 = _cffi_to_c_int(arg2, int);
  if (x2 == (int)-1 && PyErr_Occurred())
    return NULL;

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_msg_recv(x0, x1, x2); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_int(result, int);
}

static PyObject *
_cffi_f_zmq_msg_send(PyObject *self, PyObject *args)
{
  zmq_msg_t * x0;
  void * x1;
  int x2;
  Py_ssize_t datasize;
  int result;
  PyObject *arg0;
  PyObject *arg1;
  PyObject *arg2;

  if (!PyArg_ParseTuple(args, "OOO:zmq_msg_send", &arg0, &arg1, &arg2))
    return NULL;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(5), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(5), arg0) < 0)
      return NULL;
  }

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(0), arg1, (char **)&x1);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x1 = alloca((size_t)datasize);
    memset((void *)x1, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x1, _cffi_type(0), arg1) < 0)
      return NULL;
  }

  x2 = _cffi_to_c_int(arg2, int);
  if (x2 == (int)-1 && PyErr_Occurred())
    return NULL;

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_msg_send(x0, x1, x2); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_int(result, int);
}

static PyObject *
_cffi_f_zmq_msg_size(PyObject *self, PyObject *arg0)
{
  zmq_msg_t * x0;
  Py_ssize_t datasize;
  size_t result;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(5), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(5), arg0) < 0)
      return NULL;
  }

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_msg_size(x0); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_int(result, size_t);
}

static PyObject *
_cffi_f_zmq_poll(PyObject *self, PyObject *args)
{
  zmq_pollitem_t * x0;
  int x1;
  long x2;
  Py_ssize_t datasize;
  int result;
  PyObject *arg0;
  PyObject *arg1;
  PyObject *arg2;

  if (!PyArg_ParseTuple(args, "OOO:zmq_poll", &arg0, &arg1, &arg2))
    return NULL;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(7), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(7), arg0) < 0)
      return NULL;
  }

  x1 = _cffi_to_c_int(arg1, int);
  if (x1 == (int)-1 && PyErr_Occurred())
    return NULL;

  x2 = _cffi_to_c_int(arg2, long);
  if (x2 == (long)-1 && PyErr_Occurred())
    return NULL;

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_poll(x0, x1, x2); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_int(result, int);
}

static PyObject *
_cffi_f_zmq_proxy(PyObject *self, PyObject *args)
{
  void * x0;
  void * x1;
  void * x2;
  Py_ssize_t datasize;
  int result;
  PyObject *arg0;
  PyObject *arg1;
  PyObject *arg2;

  if (!PyArg_ParseTuple(args, "OOO:zmq_proxy", &arg0, &arg1, &arg2))
    return NULL;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(0), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(0), arg0) < 0)
      return NULL;
  }

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(0), arg1, (char **)&x1);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x1 = alloca((size_t)datasize);
    memset((void *)x1, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x1, _cffi_type(0), arg1) < 0)
      return NULL;
  }

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(0), arg2, (char **)&x2);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x2 = alloca((size_t)datasize);
    memset((void *)x2, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x2, _cffi_type(0), arg2) < 0)
      return NULL;
  }

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_proxy(x0, x1, x2); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_int(result, int);
}

static PyObject *
_cffi_f_zmq_setsockopt(PyObject *self, PyObject *args)
{
  void * x0;
  int x1;
  void const * x2;
  size_t x3;
  Py_ssize_t datasize;
  int result;
  PyObject *arg0;
  PyObject *arg1;
  PyObject *arg2;
  PyObject *arg3;

  if (!PyArg_ParseTuple(args, "OOOO:zmq_setsockopt", &arg0, &arg1, &arg2, &arg3))
    return NULL;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(0), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(0), arg0) < 0)
      return NULL;
  }

  x1 = _cffi_to_c_int(arg1, int);
  if (x1 == (int)-1 && PyErr_Occurred())
    return NULL;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(1), arg2, (char **)&x2);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x2 = alloca((size_t)datasize);
    memset((void *)x2, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x2, _cffi_type(1), arg2) < 0)
      return NULL;
  }

  x3 = _cffi_to_c_int(arg3, size_t);
  if (x3 == (size_t)-1 && PyErr_Occurred())
    return NULL;

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_setsockopt(x0, x1, x2, x3); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_int(result, int);
}

static PyObject *
_cffi_f_zmq_socket(PyObject *self, PyObject *args)
{
  void * x0;
  int x1;
  Py_ssize_t datasize;
  void * result;
  PyObject *arg0;
  PyObject *arg1;

  if (!PyArg_ParseTuple(args, "OO:zmq_socket", &arg0, &arg1))
    return NULL;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(0), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(0), arg0) < 0)
      return NULL;
  }

  x1 = _cffi_to_c_int(arg1, int);
  if (x1 == (int)-1 && PyErr_Occurred())
    return NULL;

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_socket(x0, x1); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_pointer((char *)result, _cffi_type(0));
}

static PyObject *
_cffi_f_zmq_socket_monitor(PyObject *self, PyObject *args)
{
  void * x0;
  char const * x1;
  int x2;
  Py_ssize_t datasize;
  int result;
  PyObject *arg0;
  PyObject *arg1;
  PyObject *arg2;

  if (!PyArg_ParseTuple(args, "OOO:zmq_socket_monitor", &arg0, &arg1, &arg2))
    return NULL;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(0), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(0), arg0) < 0)
      return NULL;
  }

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(2), arg1, (char **)&x1);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x1 = alloca((size_t)datasize);
    memset((void *)x1, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x1, _cffi_type(2), arg1) < 0)
      return NULL;
  }

  x2 = _cffi_to_c_int(arg2, int);
  if (x2 == (int)-1 && PyErr_Occurred())
    return NULL;

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_socket_monitor(x0, x1, x2); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_int(result, int);
}

static PyObject *
_cffi_f_zmq_strerror(PyObject *self, PyObject *arg0)
{
  int x0;
  char const * result;

  x0 = _cffi_to_c_int(arg0, int);
  if (x0 == (int)-1 && PyErr_Occurred())
    return NULL;

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_strerror(x0); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_pointer((char *)result, _cffi_type(2));
}

static PyObject *
_cffi_f_zmq_unbind(PyObject *self, PyObject *args)
{
  void * x0;
  char const * x1;
  Py_ssize_t datasize;
  int result;
  PyObject *arg0;
  PyObject *arg1;

  if (!PyArg_ParseTuple(args, "OO:zmq_unbind", &arg0, &arg1))
    return NULL;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(0), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(0), arg0) < 0)
      return NULL;
  }

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(2), arg1, (char **)&x1);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x1 = alloca((size_t)datasize);
    memset((void *)x1, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x1, _cffi_type(2), arg1) < 0)
      return NULL;
  }

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { result = zmq_unbind(x0, x1); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  return _cffi_from_c_int(result, int);
}

static PyObject *
_cffi_f_zmq_version(PyObject *self, PyObject *args)
{
  int * x0;
  int * x1;
  int * x2;
  Py_ssize_t datasize;
  PyObject *arg0;
  PyObject *arg1;
  PyObject *arg2;

  if (!PyArg_ParseTuple(args, "OOO:zmq_version", &arg0, &arg1, &arg2))
    return NULL;

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(8), arg0, (char **)&x0);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x0 = alloca((size_t)datasize);
    memset((void *)x0, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x0, _cffi_type(8), arg0) < 0)
      return NULL;
  }

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(8), arg1, (char **)&x1);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x1 = alloca((size_t)datasize);
    memset((void *)x1, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x1, _cffi_type(8), arg1) < 0)
      return NULL;
  }

  datasize = _cffi_prepare_pointer_call_argument(
      _cffi_type(8), arg2, (char **)&x2);
  if (datasize != 0) {
    if (datasize < 0)
      return NULL;
    x2 = alloca((size_t)datasize);
    memset((void *)x2, 0, (size_t)datasize);
    if (_cffi_convert_array_from_object((char *)x2, _cffi_type(8), arg2) < 0)
      return NULL;
  }

  Py_BEGIN_ALLOW_THREADS
  _cffi_restore_errno();
  { zmq_version(x0, x1, x2); }
  _cffi_save_errno();
  Py_END_ALLOW_THREADS

  (void)self; /* unused */
  Py_INCREF(Py_None);
  return Py_None;
}

static int _cffi_const_EADDRINUSE(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(EADDRINUSE);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "EADDRINUSE", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return ((void)lib,0);
}

static int _cffi_const_EADDRNOTAVAIL(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(EADDRNOTAVAIL);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "EADDRNOTAVAIL", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_EADDRINUSE(lib);
}

static int _cffi_const_EAFNOSUPPORT(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(EAFNOSUPPORT);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "EAFNOSUPPORT", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_EADDRNOTAVAIL(lib);
}

static int _cffi_const_EAGAIN(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(EAGAIN);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "EAGAIN", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_EAFNOSUPPORT(lib);
}

static int _cffi_const_ECONNABORTED(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ECONNABORTED);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ECONNABORTED", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_EAGAIN(lib);
}

static int _cffi_const_ECONNREFUSED(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ECONNREFUSED);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ECONNREFUSED", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ECONNABORTED(lib);
}

static int _cffi_const_ECONNRESET(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ECONNRESET);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ECONNRESET", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ECONNREFUSED(lib);
}

static int _cffi_const_EFAULT(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(EFAULT);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "EFAULT", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ECONNRESET(lib);
}

static int _cffi_const_EFSM(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(EFSM);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "EFSM", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_EFAULT(lib);
}

static int _cffi_const_EHOSTUNREACH(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(EHOSTUNREACH);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "EHOSTUNREACH", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_EFSM(lib);
}

static int _cffi_const_EINPROGRESS(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(EINPROGRESS);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "EINPROGRESS", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_EHOSTUNREACH(lib);
}

static int _cffi_const_EINVAL(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(EINVAL);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "EINVAL", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_EINPROGRESS(lib);
}

static int _cffi_const_EMSGSIZE(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(EMSGSIZE);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "EMSGSIZE", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_EINVAL(lib);
}

static int _cffi_const_EMTHREAD(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(EMTHREAD);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "EMTHREAD", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_EMSGSIZE(lib);
}

static int _cffi_const_ENETDOWN(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ENETDOWN);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ENETDOWN", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_EMTHREAD(lib);
}

static int _cffi_const_ENETRESET(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ENETRESET);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ENETRESET", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ENETDOWN(lib);
}

static int _cffi_const_ENETUNREACH(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ENETUNREACH);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ENETUNREACH", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ENETRESET(lib);
}

static int _cffi_const_ENOBUFS(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ENOBUFS);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ENOBUFS", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ENETUNREACH(lib);
}

static int _cffi_const_ENOCOMPATPROTO(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ENOCOMPATPROTO);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ENOCOMPATPROTO", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ENOBUFS(lib);
}

static int _cffi_const_ENODEV(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ENODEV);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ENODEV", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ENOCOMPATPROTO(lib);
}

static int _cffi_const_ENOMEM(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ENOMEM);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ENOMEM", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ENODEV(lib);
}

static int _cffi_const_ENOTCONN(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ENOTCONN);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ENOTCONN", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ENOMEM(lib);
}

static int _cffi_const_ENOTSOCK(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ENOTSOCK);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ENOTSOCK", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ENOTCONN(lib);
}

static int _cffi_const_ENOTSUP(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ENOTSUP);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ENOTSUP", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ENOTSOCK(lib);
}

static int _cffi_const_EPROTONOSUPPORT(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(EPROTONOSUPPORT);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "EPROTONOSUPPORT", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ENOTSUP(lib);
}

static int _cffi_const_ETERM(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ETERM);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ETERM", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_EPROTONOSUPPORT(lib);
}

static int _cffi_const_ETIMEDOUT(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ETIMEDOUT);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ETIMEDOUT", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ETERM(lib);
}

static int _cffi_const_PYZMQ_DRAFT_API(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(PYZMQ_DRAFT_API);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "PYZMQ_DRAFT_API", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ETIMEDOUT(lib);
}

static int _cffi_const_ZMQ_AFFINITY(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_AFFINITY);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_AFFINITY", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_PYZMQ_DRAFT_API(lib);
}

static int _cffi_const_ZMQ_BACKLOG(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_BACKLOG);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_BACKLOG", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_AFFINITY(lib);
}

static int _cffi_const_ZMQ_BLOCKY(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_BLOCKY);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_BLOCKY", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_BACKLOG(lib);
}

static int _cffi_const_ZMQ_CLIENT(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_CLIENT);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_CLIENT", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_BLOCKY(lib);
}

static int _cffi_const_ZMQ_CONFLATE(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_CONFLATE);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_CONFLATE", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_CLIENT(lib);
}

static int _cffi_const_ZMQ_CONNECT_RID(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_CONNECT_RID);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_CONNECT_RID", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_CONFLATE(lib);
}

static int _cffi_const_ZMQ_CONNECT_TIMEOUT(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_CONNECT_TIMEOUT);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_CONNECT_TIMEOUT", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_CONNECT_RID(lib);
}

static int _cffi_const_ZMQ_CURVE(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_CURVE);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_CURVE", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_CONNECT_TIMEOUT(lib);
}

static int _cffi_const_ZMQ_CURVE_PUBLICKEY(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_CURVE_PUBLICKEY);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_CURVE_PUBLICKEY", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_CURVE(lib);
}

static int _cffi_const_ZMQ_CURVE_SECRETKEY(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_CURVE_SECRETKEY);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_CURVE_SECRETKEY", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_CURVE_PUBLICKEY(lib);
}

static int _cffi_const_ZMQ_CURVE_SERVER(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_CURVE_SERVER);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_CURVE_SERVER", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_CURVE_SECRETKEY(lib);
}

static int _cffi_const_ZMQ_CURVE_SERVERKEY(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_CURVE_SERVERKEY);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_CURVE_SERVERKEY", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_CURVE_SERVER(lib);
}

static int _cffi_const_ZMQ_DEALER(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_DEALER);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_DEALER", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_CURVE_SERVERKEY(lib);
}

static int _cffi_const_ZMQ_DELAY_ATTACH_ON_CONNECT(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_DELAY_ATTACH_ON_CONNECT);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_DELAY_ATTACH_ON_CONNECT", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_DEALER(lib);
}

static int _cffi_const_ZMQ_DGRAM(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_DGRAM);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_DGRAM", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_DELAY_ATTACH_ON_CONNECT(lib);
}

static int _cffi_const_ZMQ_DISH(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_DISH);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_DISH", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_DGRAM(lib);
}

static int _cffi_const_ZMQ_DONTWAIT(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_DONTWAIT);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_DONTWAIT", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_DISH(lib);
}

static int _cffi_const_ZMQ_DOWNSTREAM(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_DOWNSTREAM);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_DOWNSTREAM", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_DONTWAIT(lib);
}

static int _cffi_const_ZMQ_EVENTS(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_EVENTS);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_EVENTS", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_DOWNSTREAM(lib);
}

static int _cffi_const_ZMQ_EVENT_ACCEPTED(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_EVENT_ACCEPTED);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_EVENT_ACCEPTED", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_EVENTS(lib);
}

static int _cffi_const_ZMQ_EVENT_ACCEPT_FAILED(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_EVENT_ACCEPT_FAILED);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_EVENT_ACCEPT_FAILED", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_EVENT_ACCEPTED(lib);
}

static int _cffi_const_ZMQ_EVENT_ALL(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_EVENT_ALL);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_EVENT_ALL", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_EVENT_ACCEPT_FAILED(lib);
}

static int _cffi_const_ZMQ_EVENT_BIND_FAILED(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_EVENT_BIND_FAILED);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_EVENT_BIND_FAILED", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_EVENT_ALL(lib);
}

static int _cffi_const_ZMQ_EVENT_CLOSED(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_EVENT_CLOSED);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_EVENT_CLOSED", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_EVENT_BIND_FAILED(lib);
}

static int _cffi_const_ZMQ_EVENT_CLOSE_FAILED(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_EVENT_CLOSE_FAILED);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_EVENT_CLOSE_FAILED", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_EVENT_CLOSED(lib);
}

static int _cffi_const_ZMQ_EVENT_CONNECTED(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_EVENT_CONNECTED);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_EVENT_CONNECTED", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_EVENT_CLOSE_FAILED(lib);
}

static int _cffi_const_ZMQ_EVENT_CONNECT_DELAYED(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_EVENT_CONNECT_DELAYED);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_EVENT_CONNECT_DELAYED", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_EVENT_CONNECTED(lib);
}

static int _cffi_const_ZMQ_EVENT_CONNECT_RETRIED(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_EVENT_CONNECT_RETRIED);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_EVENT_CONNECT_RETRIED", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_EVENT_CONNECT_DELAYED(lib);
}

static int _cffi_const_ZMQ_EVENT_DISCONNECTED(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_EVENT_DISCONNECTED);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_EVENT_DISCONNECTED", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_EVENT_CONNECT_RETRIED(lib);
}

static int _cffi_const_ZMQ_EVENT_LISTENING(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_EVENT_LISTENING);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_EVENT_LISTENING", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_EVENT_DISCONNECTED(lib);
}

static int _cffi_const_ZMQ_EVENT_MONITOR_STOPPED(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_EVENT_MONITOR_STOPPED);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_EVENT_MONITOR_STOPPED", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_EVENT_LISTENING(lib);
}

static int _cffi_const_ZMQ_FAIL_UNROUTABLE(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_FAIL_UNROUTABLE);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_FAIL_UNROUTABLE", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_EVENT_MONITOR_STOPPED(lib);
}

static int _cffi_const_ZMQ_FD(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_FD);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_FD", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_FAIL_UNROUTABLE(lib);
}

static int _cffi_const_ZMQ_FORWARDER(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_FORWARDER);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_FORWARDER", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_FD(lib);
}

static int _cffi_const_ZMQ_GATHER(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_GATHER);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_GATHER", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_FORWARDER(lib);
}

static int _cffi_const_ZMQ_GSSAPI(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_GSSAPI);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_GSSAPI", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_GATHER(lib);
}

static int _cffi_const_ZMQ_GSSAPI_PLAINTEXT(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_GSSAPI_PLAINTEXT);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_GSSAPI_PLAINTEXT", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_GSSAPI(lib);
}

static int _cffi_const_ZMQ_GSSAPI_PRINCIPAL(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_GSSAPI_PRINCIPAL);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_GSSAPI_PRINCIPAL", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_GSSAPI_PLAINTEXT(lib);
}

static int _cffi_const_ZMQ_GSSAPI_SERVER(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_GSSAPI_SERVER);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_GSSAPI_SERVER", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_GSSAPI_PRINCIPAL(lib);
}

static int _cffi_const_ZMQ_GSSAPI_SERVICE_PRINCIPAL(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_GSSAPI_SERVICE_PRINCIPAL);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_GSSAPI_SERVICE_PRINCIPAL", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_GSSAPI_SERVER(lib);
}

static int _cffi_const_ZMQ_HANDSHAKE_IVL(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_HANDSHAKE_IVL);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_HANDSHAKE_IVL", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_GSSAPI_SERVICE_PRINCIPAL(lib);
}

static int _cffi_const_ZMQ_HAUSNUMERO(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_HAUSNUMERO);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_HAUSNUMERO", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_HANDSHAKE_IVL(lib);
}

static int _cffi_const_ZMQ_HEARTBEAT_IVL(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_HEARTBEAT_IVL);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_HEARTBEAT_IVL", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_HAUSNUMERO(lib);
}

static int _cffi_const_ZMQ_HEARTBEAT_TIMEOUT(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_HEARTBEAT_TIMEOUT);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_HEARTBEAT_TIMEOUT", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_HEARTBEAT_IVL(lib);
}

static int _cffi_const_ZMQ_HEARTBEAT_TTL(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_HEARTBEAT_TTL);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_HEARTBEAT_TTL", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_HEARTBEAT_TIMEOUT(lib);
}

static int _cffi_const_ZMQ_HWM(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_HWM);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_HWM", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_HEARTBEAT_TTL(lib);
}

static int _cffi_const_ZMQ_IDENTITY(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_IDENTITY);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_IDENTITY", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_HWM(lib);
}

static int _cffi_const_ZMQ_IMMEDIATE(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_IMMEDIATE);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_IMMEDIATE", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_IDENTITY(lib);
}

static int _cffi_const_ZMQ_INVERT_MATCHING(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_INVERT_MATCHING);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_INVERT_MATCHING", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_IMMEDIATE(lib);
}

static int _cffi_const_ZMQ_IO_THREADS(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_IO_THREADS);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_IO_THREADS", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_INVERT_MATCHING(lib);
}

static int _cffi_const_ZMQ_IO_THREADS_DFLT(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_IO_THREADS_DFLT);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_IO_THREADS_DFLT", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_IO_THREADS(lib);
}

static int _cffi_const_ZMQ_IPC_FILTER_GID(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_IPC_FILTER_GID);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_IPC_FILTER_GID", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_IO_THREADS_DFLT(lib);
}

static int _cffi_const_ZMQ_IPC_FILTER_PID(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_IPC_FILTER_PID);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_IPC_FILTER_PID", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_IPC_FILTER_GID(lib);
}

static int _cffi_const_ZMQ_IPC_FILTER_UID(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_IPC_FILTER_UID);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_IPC_FILTER_UID", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_IPC_FILTER_PID(lib);
}

static int _cffi_const_ZMQ_IPV4ONLY(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_IPV4ONLY);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_IPV4ONLY", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_IPC_FILTER_UID(lib);
}

static int _cffi_const_ZMQ_IPV6(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_IPV6);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_IPV6", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_IPV4ONLY(lib);
}

static int _cffi_const_ZMQ_LAST_ENDPOINT(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_LAST_ENDPOINT);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_LAST_ENDPOINT", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_IPV6(lib);
}

static int _cffi_const_ZMQ_LINGER(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_LINGER);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_LINGER", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_LAST_ENDPOINT(lib);
}

static int _cffi_const_ZMQ_MAXMSGSIZE(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_MAXMSGSIZE);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_MAXMSGSIZE", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_LINGER(lib);
}

static int _cffi_const_ZMQ_MAX_SOCKETS(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_MAX_SOCKETS);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_MAX_SOCKETS", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_MAXMSGSIZE(lib);
}

static int _cffi_const_ZMQ_MAX_SOCKETS_DFLT(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_MAX_SOCKETS_DFLT);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_MAX_SOCKETS_DFLT", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_MAX_SOCKETS(lib);
}

static int _cffi_const_ZMQ_MCAST_LOOP(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_MCAST_LOOP);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_MCAST_LOOP", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_MAX_SOCKETS_DFLT(lib);
}

static int _cffi_const_ZMQ_MECHANISM(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_MECHANISM);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_MECHANISM", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_MCAST_LOOP(lib);
}

static int _cffi_const_ZMQ_MORE(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_MORE);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_MORE", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_MECHANISM(lib);
}

static int _cffi_const_ZMQ_MULTICAST_HOPS(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_MULTICAST_HOPS);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_MULTICAST_HOPS", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_MORE(lib);
}

static int _cffi_const_ZMQ_MULTICAST_MAXTPDU(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_MULTICAST_MAXTPDU);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_MULTICAST_MAXTPDU", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_MULTICAST_HOPS(lib);
}

static int _cffi_const_ZMQ_NOBLOCK(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_NOBLOCK);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_NOBLOCK", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_MULTICAST_MAXTPDU(lib);
}

static int _cffi_const_ZMQ_NULL(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_NULL);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_NULL", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_NOBLOCK(lib);
}

static int _cffi_const_ZMQ_PAIR(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_PAIR);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_PAIR", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_NULL(lib);
}

static int _cffi_const_ZMQ_PLAIN(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_PLAIN);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_PLAIN", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_PAIR(lib);
}

static int _cffi_const_ZMQ_PLAIN_PASSWORD(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_PLAIN_PASSWORD);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_PLAIN_PASSWORD", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_PLAIN(lib);
}

static int _cffi_const_ZMQ_PLAIN_SERVER(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_PLAIN_SERVER);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_PLAIN_SERVER", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_PLAIN_PASSWORD(lib);
}

static int _cffi_const_ZMQ_PLAIN_USERNAME(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_PLAIN_USERNAME);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_PLAIN_USERNAME", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_PLAIN_SERVER(lib);
}

static int _cffi_const_ZMQ_POLLERR(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_POLLERR);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_POLLERR", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_PLAIN_USERNAME(lib);
}

static int _cffi_const_ZMQ_POLLIN(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_POLLIN);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_POLLIN", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_POLLERR(lib);
}

static int _cffi_const_ZMQ_POLLITEMS_DFLT(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_POLLITEMS_DFLT);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_POLLITEMS_DFLT", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_POLLIN(lib);
}

static int _cffi_const_ZMQ_POLLOUT(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_POLLOUT);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_POLLOUT", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_POLLITEMS_DFLT(lib);
}

static int _cffi_const_ZMQ_POLLPRI(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_POLLPRI);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_POLLPRI", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_POLLOUT(lib);
}

static int _cffi_const_ZMQ_PROBE_ROUTER(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_PROBE_ROUTER);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_PROBE_ROUTER", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_POLLPRI(lib);
}

static int _cffi_const_ZMQ_PUB(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_PUB);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_PUB", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_PROBE_ROUTER(lib);
}

static int _cffi_const_ZMQ_PULL(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_PULL);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_PULL", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_PUB(lib);
}

static int _cffi_const_ZMQ_PUSH(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_PUSH);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_PUSH", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_PULL(lib);
}

static int _cffi_const_ZMQ_QUEUE(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_QUEUE);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_QUEUE", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_PUSH(lib);
}

static int _cffi_const_ZMQ_RADIO(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_RADIO);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_RADIO", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_QUEUE(lib);
}

static int _cffi_const_ZMQ_RATE(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_RATE);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_RATE", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_RADIO(lib);
}

static int _cffi_const_ZMQ_RCVBUF(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_RCVBUF);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_RCVBUF", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_RATE(lib);
}

static int _cffi_const_ZMQ_RCVHWM(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_RCVHWM);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_RCVHWM", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_RCVBUF(lib);
}

static int _cffi_const_ZMQ_RCVMORE(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_RCVMORE);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_RCVMORE", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_RCVHWM(lib);
}

static int _cffi_const_ZMQ_RCVTIMEO(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_RCVTIMEO);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_RCVTIMEO", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_RCVMORE(lib);
}

static int _cffi_const_ZMQ_RECONNECT_IVL(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_RECONNECT_IVL);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_RECONNECT_IVL", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_RCVTIMEO(lib);
}

static int _cffi_const_ZMQ_RECONNECT_IVL_MAX(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_RECONNECT_IVL_MAX);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_RECONNECT_IVL_MAX", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_RECONNECT_IVL(lib);
}

static int _cffi_const_ZMQ_RECOVERY_IVL(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_RECOVERY_IVL);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_RECOVERY_IVL", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_RECONNECT_IVL_MAX(lib);
}

static int _cffi_const_ZMQ_RECOVERY_IVL_MSEC(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_RECOVERY_IVL_MSEC);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_RECOVERY_IVL_MSEC", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_RECOVERY_IVL(lib);
}

static int _cffi_const_ZMQ_REP(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_REP);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_REP", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_RECOVERY_IVL_MSEC(lib);
}

static int _cffi_const_ZMQ_REQ(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_REQ);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_REQ", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_REP(lib);
}

static int _cffi_const_ZMQ_REQ_CORRELATE(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_REQ_CORRELATE);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_REQ_CORRELATE", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_REQ(lib);
}

static int _cffi_const_ZMQ_REQ_RELAXED(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_REQ_RELAXED);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_REQ_RELAXED", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_REQ_CORRELATE(lib);
}

static int _cffi_const_ZMQ_ROUTER(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_ROUTER);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_ROUTER", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_REQ_RELAXED(lib);
}

static int _cffi_const_ZMQ_ROUTER_BEHAVIOR(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_ROUTER_BEHAVIOR);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_ROUTER_BEHAVIOR", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_ROUTER(lib);
}

static int _cffi_const_ZMQ_ROUTER_HANDOVER(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_ROUTER_HANDOVER);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_ROUTER_HANDOVER", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_ROUTER_BEHAVIOR(lib);
}

static int _cffi_const_ZMQ_ROUTER_MANDATORY(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_ROUTER_MANDATORY);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_ROUTER_MANDATORY", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_ROUTER_HANDOVER(lib);
}

static int _cffi_const_ZMQ_ROUTER_RAW(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_ROUTER_RAW);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_ROUTER_RAW", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_ROUTER_MANDATORY(lib);
}

static int _cffi_const_ZMQ_SCATTER(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_SCATTER);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_SCATTER", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_ROUTER_RAW(lib);
}

static int _cffi_const_ZMQ_SERVER(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_SERVER);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_SERVER", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_SCATTER(lib);
}

static int _cffi_const_ZMQ_SHARED(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_SHARED);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_SHARED", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_SERVER(lib);
}

static int _cffi_const_ZMQ_SNDBUF(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_SNDBUF);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_SNDBUF", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_SHARED(lib);
}

static int _cffi_const_ZMQ_SNDHWM(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_SNDHWM);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_SNDHWM", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_SNDBUF(lib);
}

static int _cffi_const_ZMQ_SNDMORE(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_SNDMORE);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_SNDMORE", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_SNDHWM(lib);
}

static int _cffi_const_ZMQ_SNDTIMEO(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_SNDTIMEO);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_SNDTIMEO", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_SNDMORE(lib);
}

static int _cffi_const_ZMQ_SOCKET_LIMIT(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_SOCKET_LIMIT);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_SOCKET_LIMIT", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_SNDTIMEO(lib);
}

static int _cffi_const_ZMQ_SOCKS_PROXY(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_SOCKS_PROXY);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_SOCKS_PROXY", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_SOCKET_LIMIT(lib);
}

static int _cffi_const_ZMQ_SRCFD(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_SRCFD);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_SRCFD", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_SOCKS_PROXY(lib);
}

static int _cffi_const_ZMQ_STREAM(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_STREAM);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_STREAM", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_SRCFD(lib);
}

static int _cffi_const_ZMQ_STREAMER(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_STREAMER);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_STREAMER", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_STREAM(lib);
}

static int _cffi_const_ZMQ_STREAM_NOTIFY(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_STREAM_NOTIFY);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_STREAM_NOTIFY", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_STREAMER(lib);
}

static int _cffi_const_ZMQ_SUB(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_SUB);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_SUB", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_STREAM_NOTIFY(lib);
}

static int _cffi_const_ZMQ_SUBSCRIBE(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_SUBSCRIBE);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_SUBSCRIBE", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_SUB(lib);
}

static int _cffi_const_ZMQ_SWAP(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_SWAP);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_SWAP", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_SUBSCRIBE(lib);
}

static int _cffi_const_ZMQ_TCP_ACCEPT_FILTER(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_TCP_ACCEPT_FILTER);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_TCP_ACCEPT_FILTER", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_SWAP(lib);
}

static int _cffi_const_ZMQ_TCP_KEEPALIVE(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_TCP_KEEPALIVE);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_TCP_KEEPALIVE", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_TCP_ACCEPT_FILTER(lib);
}

static int _cffi_const_ZMQ_TCP_KEEPALIVE_CNT(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_TCP_KEEPALIVE_CNT);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_TCP_KEEPALIVE_CNT", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_TCP_KEEPALIVE(lib);
}

static int _cffi_const_ZMQ_TCP_KEEPALIVE_IDLE(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_TCP_KEEPALIVE_IDLE);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_TCP_KEEPALIVE_IDLE", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_TCP_KEEPALIVE_CNT(lib);
}

static int _cffi_const_ZMQ_TCP_KEEPALIVE_INTVL(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_TCP_KEEPALIVE_INTVL);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_TCP_KEEPALIVE_INTVL", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_TCP_KEEPALIVE_IDLE(lib);
}

static int _cffi_const_ZMQ_TCP_MAXRT(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_TCP_MAXRT);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_TCP_MAXRT", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_TCP_KEEPALIVE_INTVL(lib);
}

static int _cffi_const_ZMQ_THREAD_PRIORITY(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_THREAD_PRIORITY);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_THREAD_PRIORITY", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_TCP_MAXRT(lib);
}

static int _cffi_const_ZMQ_THREAD_PRIORITY_DFLT(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_THREAD_PRIORITY_DFLT);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_THREAD_PRIORITY_DFLT", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_THREAD_PRIORITY(lib);
}

static int _cffi_const_ZMQ_THREAD_SAFE(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_THREAD_SAFE);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_THREAD_SAFE", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_THREAD_PRIORITY_DFLT(lib);
}

static int _cffi_const_ZMQ_THREAD_SCHED_POLICY(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_THREAD_SCHED_POLICY);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_THREAD_SCHED_POLICY", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_THREAD_SAFE(lib);
}

static int _cffi_const_ZMQ_THREAD_SCHED_POLICY_DFLT(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_THREAD_SCHED_POLICY_DFLT);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_THREAD_SCHED_POLICY_DFLT", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_THREAD_SCHED_POLICY(lib);
}

static int _cffi_const_ZMQ_TOS(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_TOS);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_TOS", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_THREAD_SCHED_POLICY_DFLT(lib);
}

static int _cffi_const_ZMQ_TYPE(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_TYPE);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_TYPE", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_TOS(lib);
}

static int _cffi_const_ZMQ_UNSUBSCRIBE(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_UNSUBSCRIBE);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_UNSUBSCRIBE", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_TYPE(lib);
}

static int _cffi_const_ZMQ_UPSTREAM(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_UPSTREAM);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_UPSTREAM", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_UNSUBSCRIBE(lib);
}

static int _cffi_const_ZMQ_USE_FD(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_USE_FD);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_USE_FD", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_UPSTREAM(lib);
}

static int _cffi_const_ZMQ_VERSION(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_VERSION);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_VERSION", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_USE_FD(lib);
}

static int _cffi_const_ZMQ_VERSION_MAJOR(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_VERSION_MAJOR);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_VERSION_MAJOR", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_VERSION(lib);
}

static int _cffi_const_ZMQ_VERSION_MINOR(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_VERSION_MINOR);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_VERSION_MINOR", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_VERSION_MAJOR(lib);
}

static int _cffi_const_ZMQ_VERSION_PATCH(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_VERSION_PATCH);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_VERSION_PATCH", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_VERSION_MINOR(lib);
}

static int _cffi_const_ZMQ_VMCI_BUFFER_MAX_SIZE(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_VMCI_BUFFER_MAX_SIZE);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_VMCI_BUFFER_MAX_SIZE", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_VERSION_PATCH(lib);
}

static int _cffi_const_ZMQ_VMCI_BUFFER_MIN_SIZE(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_VMCI_BUFFER_MIN_SIZE);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_VMCI_BUFFER_MIN_SIZE", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_VMCI_BUFFER_MAX_SIZE(lib);
}

static int _cffi_const_ZMQ_VMCI_BUFFER_SIZE(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_VMCI_BUFFER_SIZE);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_VMCI_BUFFER_SIZE", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_VMCI_BUFFER_MIN_SIZE(lib);
}

static int _cffi_const_ZMQ_VMCI_CONNECT_TIMEOUT(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_VMCI_CONNECT_TIMEOUT);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_VMCI_CONNECT_TIMEOUT", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_VMCI_BUFFER_SIZE(lib);
}

static int _cffi_const_ZMQ_XPUB(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_XPUB);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_XPUB", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_VMCI_CONNECT_TIMEOUT(lib);
}

static int _cffi_const_ZMQ_XPUB_MANUAL(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_XPUB_MANUAL);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_XPUB_MANUAL", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_XPUB(lib);
}

static int _cffi_const_ZMQ_XPUB_NODROP(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_XPUB_NODROP);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_XPUB_NODROP", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_XPUB_MANUAL(lib);
}

static int _cffi_const_ZMQ_XPUB_VERBOSE(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_XPUB_VERBOSE);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_XPUB_VERBOSE", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_XPUB_NODROP(lib);
}

static int _cffi_const_ZMQ_XPUB_VERBOSER(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_XPUB_VERBOSER);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_XPUB_VERBOSER", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_XPUB_VERBOSE(lib);
}

static int _cffi_const_ZMQ_XPUB_WELCOME_MSG(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_XPUB_WELCOME_MSG);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_XPUB_WELCOME_MSG", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_XPUB_VERBOSER(lib);
}

static int _cffi_const_ZMQ_XREP(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_XREP);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_XREP", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_XPUB_WELCOME_MSG(lib);
}

static int _cffi_const_ZMQ_XREQ(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_XREQ);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_XREQ", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_XREP(lib);
}

static int _cffi_const_ZMQ_XSUB(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_XSUB);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_XSUB", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_XREQ(lib);
}

static int _cffi_const_ZMQ_ZAP_DOMAIN(PyObject *lib)
{
  PyObject *o;
  int res;
  o = _cffi_from_c_int_const(ZMQ_ZAP_DOMAIN);
  if (o == NULL)
    return -1;
  res = PyObject_SetAttrString(lib, "ZMQ_ZAP_DOMAIN", o);
  Py_DECREF(o);
  if (res < 0)
    return -1;
  return _cffi_const_ZMQ_XSUB(lib);
}

static int _cffi_setup_custom(PyObject *lib)
{
  return _cffi_const_ZMQ_ZAP_DOMAIN(lib);
}

static PyMethodDef _cffi_methods[] = {
  {"_cffi_layout__zmq_msg_t", _cffi_layout__zmq_msg_t, METH_NOARGS, NULL},
  {"_cffi_layout__zmq_pollitem_t", _cffi_layout__zmq_pollitem_t, METH_NOARGS, NULL},
  {"get_ipc_path_max_len", _cffi_f_get_ipc_path_max_len, METH_NOARGS, NULL},
  {"memcpy", _cffi_f_memcpy, METH_VARARGS, NULL},
  {"zmq_bind", _cffi_f_zmq_bind, METH_VARARGS, NULL},
  {"zmq_close", _cffi_f_zmq_close, METH_O, NULL},
  {"zmq_connect", _cffi_f_zmq_connect, METH_VARARGS, NULL},
  {"zmq_ctx_destroy", _cffi_f_zmq_ctx_destroy, METH_O, NULL},
  {"zmq_ctx_get", _cffi_f_zmq_ctx_get, METH_VARARGS, NULL},
  {"zmq_ctx_new", _cffi_f_zmq_ctx_new, METH_NOARGS, NULL},
  {"zmq_ctx_set", _cffi_f_zmq_ctx_set, METH_VARARGS, NULL},
  {"zmq_curve_keypair", _cffi_f_zmq_curve_keypair, METH_VARARGS, NULL},
  {"zmq_curve_public", _cffi_f_zmq_curve_public, METH_VARARGS, NULL},
  {"zmq_device", _cffi_f_zmq_device, METH_VARARGS, NULL},
  {"zmq_disconnect", _cffi_f_zmq_disconnect, METH_VARARGS, NULL},
  {"zmq_errno", _cffi_f_zmq_errno, METH_NOARGS, NULL},
  {"zmq_getsockopt", _cffi_f_zmq_getsockopt, METH_VARARGS, NULL},
  {"zmq_has", _cffi_f_zmq_has, METH_O, NULL},
  {"zmq_msg_close", _cffi_f_zmq_msg_close, METH_O, NULL},
  {"zmq_msg_data", _cffi_f_zmq_msg_data, METH_O, NULL},
  {"zmq_msg_init", _cffi_f_zmq_msg_init, METH_O, NULL},
  {"zmq_msg_init_data", _cffi_f_zmq_msg_init_data, METH_VARARGS, NULL},
  {"zmq_msg_init_size", _cffi_f_zmq_msg_init_size, METH_VARARGS, NULL},
  {"zmq_msg_recv", _cffi_f_zmq_msg_recv, METH_VARARGS, NULL},
  {"zmq_msg_send", _cffi_f_zmq_msg_send, METH_VARARGS, NULL},
  {"zmq_msg_size", _cffi_f_zmq_msg_size, METH_O, NULL},
  {"zmq_poll", _cffi_f_zmq_poll, METH_VARARGS, NULL},
  {"zmq_proxy", _cffi_f_zmq_proxy, METH_VARARGS, NULL},
  {"zmq_setsockopt", _cffi_f_zmq_setsockopt, METH_VARARGS, NULL},
  {"zmq_socket", _cffi_f_zmq_socket, METH_VARARGS, NULL},
  {"zmq_socket_monitor", _cffi_f_zmq_socket_monitor, METH_VARARGS, NULL},
  {"zmq_strerror", _cffi_f_zmq_strerror, METH_O, NULL},
  {"zmq_unbind", _cffi_f_zmq_unbind, METH_VARARGS, NULL},
  {"zmq_version", _cffi_f_zmq_version, METH_VARARGS, NULL},
  {"_cffi_setup", _cffi_setup, METH_VARARGS, NULL},
  {NULL, NULL, 0, NULL}    /* Sentinel */
};

#if PY_MAJOR_VERSION >= 3

static struct PyModuleDef _cffi_module_def = {
  PyModuleDef_HEAD_INIT,
  "_cffi_ext",
  NULL,
  -1,
  _cffi_methods,
  NULL, NULL, NULL, NULL
};

PyMODINIT_FUNC
PyInit__cffi_ext(void)
{
  PyObject *lib;
  lib = PyModule_Create(&_cffi_module_def);
  if (lib == NULL)
    return NULL;
  if (((void)lib,0) < 0 || _cffi_init() < 0) {
    Py_DECREF(lib);
    return NULL;
  }
  return lib;
}

#else

PyMODINIT_FUNC
init_cffi_ext(void)
{
  PyObject *lib;
  lib = Py_InitModule("_cffi_ext", _cffi_methods);
  if (lib == NULL)
    return;
  if (((void)lib,0) < 0 || _cffi_init() < 0)
    return;
  return;
}

#endif
