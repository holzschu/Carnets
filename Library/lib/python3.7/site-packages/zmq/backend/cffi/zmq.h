/*
    Copyright (c) 2007-2016 Contributors as noted in the AUTHORS file

    This file is part of libzmq, the ZeroMQ core engine in C++.

    libzmq is free software; you can redistribute it and/or modify it under
    the terms of the GNU Lesser General Public License (LGPL) as published
    by the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.

    As a special exception, the Contributors give you permission to link
    this library with independent modules to produce an executable,
    regardless of the license terms of these independent modules, and to
    copy and distribute the resulting executable under terms of your choice,
    provided that you also meet, for each linked independent module, the
    terms and conditions of the license of that module. An independent
    module is a module which is not derived from or based on this library.
    If you modify this library, you must extend this exception to your
    version of the library.

    libzmq is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
    FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
    License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    *************************************************************************
    NOTE to contributors. This file comprises the principal public contract
    for ZeroMQ API users. Any change to this file supplied in a stable
    release SHOULD not break existing applications.
    In practice this means that the value of constants must not change, and
    that old values may not be reused for new constants.
    *************************************************************************
*/

// iOS: file zmq.h from pyzmq-17.1.2 distribution, 
// heavily edited so it can be parsed by ffi.cdef
int get_ipc_path_max_len(void);

/*  Version macros for compile-time API version detection                     */
#define ZMQ_VERSION_MAJOR 4
#define ZMQ_VERSION_MINOR 2
#define ZMQ_VERSION_PATCH 5

// #define ZMQ_MAKE_VERSION(major, minor, patch) \
    ((major) * 10000 + (minor) * 100 + (patch))
#define ZMQ_VERSION 40205
//    ZMQ_MAKE_VERSION(ZMQ_VERSION_MAJOR, ZMQ_VERSION_MINOR, ZMQ_VERSION_PATCH)


/*  Define integer types needed for event interface                          */
#define ZMQ_DEFINED_STDINT 1

/******************************************************************************/
/*  0MQ errors.                                                               */
/******************************************************************************/

/*  A number random enough not to collide with different errno ranges on      */
/*  different OSes. The assumption is that error_t is at least 32-bit type.   */
#define ZMQ_HAUSNUMERO 156384712

/*  On Windows platform some of the standard POSIX errnos are not defined.    */
#define ENOTSUP 156384713 // (ZMQ_HAUSNUMERO + 1)
#define EPROTONOSUPPORT 156384714 //(ZMQ_HAUSNUMERO + 2)
#define ENOBUFS 156384715 // (ZMQ_HAUSNUMERO + 3)
#define ENETDOWN 156384716  // (ZMQ_HAUSNUMERO + 4)
#define EADDRINUSE 156384717  // (ZMQ_HAUSNUMERO + 5)
#define EADDRNOTAVAIL 156384718  // (ZMQ_HAUSNUMERO + 6)
#define ECONNREFUSED 156384719  // (ZMQ_HAUSNUMERO + 7)
#define EINPROGRESS 156384720  // (ZMQ_HAUSNUMERO + 8)
#define ENOTSOCK 156384721  // (ZMQ_HAUSNUMERO + 9)
#define EMSGSIZE 156384722  // (ZMQ_HAUSNUMERO + 10)
#define EAFNOSUPPORT 156384723  // (ZMQ_HAUSNUMERO + 11)
#define ENETUNREACH 156384724  // (ZMQ_HAUSNUMERO + 12)
#define ECONNABORTED 156384725  // (ZMQ_HAUSNUMERO + 13)
#define ECONNRESET 156384726  // (ZMQ_HAUSNUMERO + 14)
#define ENOTCONN 156384727  // (ZMQ_HAUSNUMERO + 15)
#define ETIMEDOUT 156384728  // (ZMQ_HAUSNUMERO + 16)
#define EHOSTUNREACH 156384729  // (ZMQ_HAUSNUMERO + 17)
#define ENETRESET 156384730  // (ZMQ_HAUSNUMERO + 18)

/*  Native 0MQ error codes.                                                   */
#define EFSM 156384763  // (ZMQ_HAUSNUMERO + 51)
#define ENOCOMPATPROTO 156384764  // (ZMQ_HAUSNUMERO + 52)
#define ETERM 156384765  // (ZMQ_HAUSNUMERO + 53)
#define EMTHREAD 156384766  // (ZMQ_HAUSNUMERO + 54)

/*  This function retrieves the errno as it is known to 0MQ library. The goal */
/*  of this function is to make the code 100% portable, including where 0MQ   */
/*  compiled with certain CRT library (on Windows) is linked to an            */
/*  application that uses different CRT library.                              */
 int zmq_errno (void);

/*  Resolves system errors and 0MQ errors to human-readable string.           */
 const char *zmq_strerror (int errnum);

/*  Run-time API version detection                                            */
 void zmq_version (int *major, int *minor, int *patch);

/******************************************************************************/
/*  0MQ infrastructure (a.k.a. context) initialisation & termination.         */
/******************************************************************************/

/*  Context options                                                           */
#define ZMQ_IO_THREADS 1
#define ZMQ_MAX_SOCKETS 2
#define ZMQ_SOCKET_LIMIT 3
#define ZMQ_THREAD_PRIORITY 3
#define ZMQ_THREAD_SCHED_POLICY 4
#define ZMQ_MAX_MSGSZ 5

/*  Default for new contexts                                                  */
#define ZMQ_IO_THREADS_DFLT 1
#define ZMQ_MAX_SOCKETS_DFLT 1023
#define ZMQ_THREAD_PRIORITY_DFLT -1
#define ZMQ_THREAD_SCHED_POLICY_DFLT -1

 void *zmq_ctx_new (void);
 int zmq_ctx_term (void *context);
 int zmq_ctx_shutdown (void *context);
 int zmq_ctx_set (void *context, int option, int optval);
 int zmq_ctx_get (void *context, int option);

/*  Old (legacy) API                                                          */
 void *zmq_init (int io_threads);
 int zmq_term (void *context);
 int zmq_ctx_destroy (void *context);


/******************************************************************************/
/*  0MQ message definition.                                                   */
/******************************************************************************/

/* Some architectures, like sparc64 and some variants of aarch64, enforce pointer
 * alignment and raise sigbus on violations. Make sure applications allocate
 * zmq_msg_t on addresses aligned on a pointer-size boundary to avoid this issue.
 */
typedef struct zmq_msg_t
{
    unsigned char _ [64];
} zmq_msg_t;

typedef void(zmq_free_fn) (void *data, void *hint);

 int zmq_msg_init (zmq_msg_t *msg);
 int zmq_msg_init_size (zmq_msg_t *msg, size_t size);
 int zmq_msg_init_data (
  zmq_msg_t *msg, void *data, size_t size, zmq_free_fn *ffn, void *hint);
 int zmq_msg_send (zmq_msg_t *msg, void *s, int flags);
 int zmq_msg_recv (zmq_msg_t *msg, void *s, int flags);
 int zmq_msg_close (zmq_msg_t *msg);
 int zmq_msg_move (zmq_msg_t *dest, zmq_msg_t *src);
 int zmq_msg_copy (zmq_msg_t *dest, zmq_msg_t *src);
 void *zmq_msg_data (zmq_msg_t *msg);
 size_t zmq_msg_size (const zmq_msg_t *msg);
 int zmq_msg_more (const zmq_msg_t *msg);
 int zmq_msg_get (const zmq_msg_t *msg, int property);
 int zmq_msg_set (zmq_msg_t *msg, int property, int optval);
 const char *zmq_msg_gets (const zmq_msg_t *msg,
                           const char *property);

/******************************************************************************/
/*  0MQ socket definition.                                                    */
/******************************************************************************/

/*  Socket types.                                                             */
#define ZMQ_PAIR 0
#define ZMQ_PUB 1
#define ZMQ_SUB 2
#define ZMQ_REQ 3
#define ZMQ_REP 4
#define ZMQ_DEALER 5
#define ZMQ_ROUTER 6
#define ZMQ_PULL 7
#define ZMQ_PUSH 8
#define ZMQ_XPUB 9
#define ZMQ_XSUB 10
#define ZMQ_STREAM 11

/*  Deprecated aliases                                                        */
#define ZMQ_XREQ 5 // ZMQ_DEALER
#define ZMQ_XREP 6 // ZMQ_ROUTER

/*  Socket options.                                                           */
#define ZMQ_AFFINITY 4
#define ZMQ_ROUTING_ID 5
#define ZMQ_SUBSCRIBE 6
#define ZMQ_UNSUBSCRIBE 7
#define ZMQ_RATE 8
#define ZMQ_RECOVERY_IVL 9
#define ZMQ_SNDBUF 11
#define ZMQ_RCVBUF 12
#define ZMQ_RCVMORE 13
#define ZMQ_FD 14
#define ZMQ_EVENTS 15
#define ZMQ_TYPE 16
#define ZMQ_LINGER 17
#define ZMQ_RECONNECT_IVL 18
#define ZMQ_BACKLOG 19
#define ZMQ_RECONNECT_IVL_MAX 21
#define ZMQ_MAXMSGSIZE 22
#define ZMQ_SNDHWM 23
#define ZMQ_RCVHWM 24
#define ZMQ_MULTICAST_HOPS 25
#define ZMQ_RCVTIMEO 27
#define ZMQ_SNDTIMEO 28
#define ZMQ_LAST_ENDPOINT 32
#define ZMQ_ROUTER_MANDATORY 33
#define ZMQ_TCP_KEEPALIVE 34
#define ZMQ_TCP_KEEPALIVE_CNT 35
#define ZMQ_TCP_KEEPALIVE_IDLE 36
#define ZMQ_TCP_KEEPALIVE_INTVL 37
#define ZMQ_IMMEDIATE 39
#define ZMQ_XPUB_VERBOSE 40
#define ZMQ_ROUTER_RAW 41
#define ZMQ_IPV6 42
#define ZMQ_MECHANISM 43
#define ZMQ_PLAIN_SERVER 44
#define ZMQ_PLAIN_USERNAME 45
#define ZMQ_PLAIN_PASSWORD 46
#define ZMQ_CURVE_SERVER 47
#define ZMQ_CURVE_PUBLICKEY 48
#define ZMQ_CURVE_SECRETKEY 49
#define ZMQ_CURVE_SERVERKEY 50
#define ZMQ_PROBE_ROUTER 51
#define ZMQ_REQ_CORRELATE 52
#define ZMQ_REQ_RELAXED 53
#define ZMQ_CONFLATE 54
#define ZMQ_ZAP_DOMAIN 55
#define ZMQ_ROUTER_HANDOVER 56
#define ZMQ_TOS 57
#define ZMQ_CONNECT_ROUTING_ID 61
#define ZMQ_GSSAPI_SERVER 62
#define ZMQ_GSSAPI_PRINCIPAL 63
#define ZMQ_GSSAPI_SERVICE_PRINCIPAL 64
#define ZMQ_GSSAPI_PLAINTEXT 65
#define ZMQ_HANDSHAKE_IVL 66
#define ZMQ_SOCKS_PROXY 68
#define ZMQ_XPUB_NODROP 69
#define ZMQ_BLOCKY 70
#define ZMQ_XPUB_MANUAL 71
#define ZMQ_XPUB_WELCOME_MSG 72
#define ZMQ_STREAM_NOTIFY 73
#define ZMQ_INVERT_MATCHING 74
#define ZMQ_HEARTBEAT_IVL 75
#define ZMQ_HEARTBEAT_TTL 76
#define ZMQ_HEARTBEAT_TIMEOUT 77
#define ZMQ_XPUB_VERBOSER 78
#define ZMQ_CONNECT_TIMEOUT 79
#define ZMQ_TCP_MAXRT 80
#define ZMQ_THREAD_SAFE 81
#define ZMQ_MULTICAST_MAXTPDU 84
#define ZMQ_VMCI_BUFFER_SIZE 85
#define ZMQ_VMCI_BUFFER_MIN_SIZE 86
#define ZMQ_VMCI_BUFFER_MAX_SIZE 87
#define ZMQ_VMCI_CONNECT_TIMEOUT 88
#define ZMQ_USE_FD 89

/*  Message options                                                           */
#define ZMQ_MORE 1
#define ZMQ_SHARED 3

/*  Send/recv options.                                                        */
#define ZMQ_DONTWAIT 1
#define ZMQ_SNDMORE 2

/*  Security mechanisms                                                       */
#define ZMQ_NULL 0
#define ZMQ_PLAIN 1
#define ZMQ_CURVE 2
#define ZMQ_GSSAPI 3

/*  RADIO-DISH protocol                                                       */
#define ZMQ_GROUP_MAX_LENGTH 15

/*  Deprecated options and aliases                                            */
#define ZMQ_IDENTITY                5 // ZMQ_ROUTING_ID
#define ZMQ_CONNECT_RID             61 // ZMQ_CONNECT_ROUTING_ID
#define ZMQ_TCP_ACCEPT_FILTER       38
#define ZMQ_IPC_FILTER_PID          58
#define ZMQ_IPC_FILTER_UID          59
#define ZMQ_IPC_FILTER_GID          60
#define ZMQ_IPV4ONLY                31
#define ZMQ_DELAY_ATTACH_ON_CONNECT 39 // ZMQ_IMMEDIATE
#define ZMQ_NOBLOCK                 1 // ZMQ_DONTWAIT
#define ZMQ_FAIL_UNROUTABLE         33 // ZMQ_ROUTER_MANDATORY
#define ZMQ_ROUTER_BEHAVIOR         33 // ZMQ_ROUTER_MANDATORY

/*  Deprecated Message options                                                */
#define ZMQ_SRCFD 2

/******************************************************************************/
/*  0MQ socket events and monitoring                                          */
/******************************************************************************/

/*  Socket transport events (TCP, IPC and TIPC only)                          */

#define ZMQ_EVENT_CONNECTED         0x0001
#define ZMQ_EVENT_CONNECT_DELAYED   0x0002
#define ZMQ_EVENT_CONNECT_RETRIED   0x0004
#define ZMQ_EVENT_LISTENING         0x0008
#define ZMQ_EVENT_BIND_FAILED       0x0010
#define ZMQ_EVENT_ACCEPTED          0x0020
#define ZMQ_EVENT_ACCEPT_FAILED     0x0040
#define ZMQ_EVENT_CLOSED            0x0080
#define ZMQ_EVENT_CLOSE_FAILED      0x0100
#define ZMQ_EVENT_DISCONNECTED      0x0200
#define ZMQ_EVENT_MONITOR_STOPPED   0x0400
#define ZMQ_EVENT_ALL               0xFFFF

 void *zmq_socket (void *, int type);
 int zmq_close (void *s);
 int zmq_setsockopt (void *s, int option, const void *optval, size_t optvallen);
 int zmq_getsockopt (void *s, int option, void *optval, size_t *optvallen);
 int zmq_bind (void *s, const char *addr);
 int zmq_connect (void *s, const char *addr);
 int zmq_unbind (void *s, const char *addr);
 int zmq_disconnect (void *s, const char *addr);
 int zmq_send (void *s, const void *buf, size_t len, int flags);
 int zmq_send_const (void *s, const void *buf, size_t len, int flags);
 int zmq_recv (void *s, void *buf, size_t len, int flags);
 int zmq_socket_monitor (void *s, const char *addr, int events);


/******************************************************************************/
/*  Deprecated I/O multiplexing. Prefer using zmq_poller API                  */
/******************************************************************************/

#define ZMQ_POLLIN 1
#define ZMQ_POLLOUT 2
#define ZMQ_POLLERR 4
#define ZMQ_POLLPRI 8

typedef struct zmq_pollitem_t
{
    void *socket;
    int fd;
    short events;
    short revents;
} zmq_pollitem_t;

#define ZMQ_POLLITEMS_DFLT 16

 int zmq_poll (zmq_pollitem_t *items, int nitems, long timeout);

/******************************************************************************/
/*  Message proxying                                                          */
/******************************************************************************/

 int zmq_proxy (void *frontend, void *backend, void *capture);
 int zmq_proxy_steerable (void *frontend, void *backend, void *capture, void *control);

/******************************************************************************/
/*  Probe library capabilities                                                */
/******************************************************************************/

#define ZMQ_HAS_CAPABILITIES 1
 int zmq_has (const char *capability);

/*  Deprecated aliases */
#define ZMQ_STREAMER 1
#define ZMQ_FORWARDER 2
#define ZMQ_QUEUE 3

/*  Deprecated methods */
 int zmq_device (int type, void *frontend, void *backend);
 int zmq_sendmsg (void *s, zmq_msg_t *msg, int flags);
 int zmq_recvmsg (void *s, zmq_msg_t *msg, int flags);
struct iovec;
 int zmq_sendiov (void *s, struct iovec *iov, size_t count, int flags);
 int zmq_recviov (void *s, struct iovec *iov, size_t *count, int flags);

/******************************************************************************/
/*  Encryption functions                                                      */
/******************************************************************************/

/*  Encode data with Z85 encoding. Returns encoded data                       */
 char *zmq_z85_encode (char *dest, const uint8_t *data, size_t size);

/*  Decode data with Z85 encoding. Returns decoded data                       */
 uint8_t *zmq_z85_decode (uint8_t *dest, const char *string);

/*  Generate z85-encoded public and private keypair with tweetnacl/libsodium. */
/*  Returns 0 on success.                                                     */
 int zmq_curve_keypair (char *z85_public_key, char *z85_secret_key);

/*  Derive the z85-encoded public key from the z85-encoded secret key.        */
/*  Returns 0 on success.                                                     */
 int zmq_curve_public (char *z85_public_key, const char *z85_secret_key);

/******************************************************************************/
/*  Atomic utility methods                                                    */
/******************************************************************************/

 void *zmq_atomic_counter_new (void);
 void zmq_atomic_counter_set (void *counter, int value);
 int zmq_atomic_counter_inc (void *counter);
 int zmq_atomic_counter_dec (void *counter);
 int zmq_atomic_counter_value (void *counter);
 void zmq_atomic_counter_destroy (void **counter_p);


/******************************************************************************/
/*  These functions are not documented by man pages -- use at your own risk.  */
/*  If you need these to be part of the formal ZMQ API, then (a) write a man  */
/*  page, and (b) write a test case in tests.                                 */
/******************************************************************************/

/*  Helper functions are used by perf tests so that they don't have to care   */
/*  about minutiae of time-related functions on different OS platforms.       */

/*  Starts the stopwatch. Returns the handle to the watch.                    */
 void *zmq_stopwatch_start (void);

/*  Stops the stopwatch. Returns the number of microseconds elapsed since     */
/*  the stopwatch was started, and deallocates that watch.                    */
 unsigned long zmq_stopwatch_stop (void *watch_);

/*  Sleeps for specified number of seconds.                                   */
 void zmq_sleep (int seconds_);

typedef void(zmq_thread_fn) (void *);

/* Start a thread. Returns a handle to the thread.                            */
 void *zmq_threadstart (zmq_thread_fn *func, void *arg);

/* Wait for thread to complete then free up resources.                        */
 void zmq_threadclose (void *thread);

// constants from zmq_constant.h

#define PYZMQ_DRAFT_API 0

#define _PYZMQ_UNDEFINED -9999
    #define ZMQ_UPSTREAM -9999
    #define ZMQ_DOWNSTREAM -9999
    #define ZMQ_SERVER -9999
    #define ZMQ_CLIENT -9999
    #define ZMQ_RADIO -9999
    #define ZMQ_DISH -9999
    #define ZMQ_GATHER -9999
    #define ZMQ_SCATTER -9999
    #define ZMQ_DGRAM -9999
 // from errno.h
#define EAGAIN 35
#define EINVAL 22
#define EFAULT 14
#define ENOMEM 12
#define ENODEV 19
#define EMSGSIZE 40
#define EAFNOSUPPORT 47
#define ENETUNREACH 51
#define ECONNABORTED 53
#define ECONNRESET 54
#define ENOTCONN 57
#define ETIMEDOUT 60
#define EHOSTUNREACH 65
#define ENETRESET 52
#define ENOTSUP 45
#define EPROTONOSUPPORT 43
#define ENOBUFS 55
#define ENETDOWN 50
#define EADDRINUSE 48
#define EADDRNOTAVAIL 49
#define ECONNREFUSED 61
#define EINPROGRESS 36
#define ENOTSOCK 38
    #define ZMQ_HWM -9999
    #define ZMQ_SWAP -9999
    #define ZMQ_MCAST_LOOP -9999
    #define ZMQ_RECOVERY_IVL_MSEC -9999
