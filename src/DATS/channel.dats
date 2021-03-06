#include "./../HATS/includes.hats"
staload "./../SATS/channel.sats"
#define ATS_DYNLOADFLAG 0

%{^
#include <pthread.h>
%}

absimpl channel_vtype(a: vt0p) = channel_
absimpl queue_vtype(a: vt0p, id: int) = deqarray(a)
absimpl ISNIL(id: int, b: bool) = unit_p
absimpl ISFULL(id: int, b: bool) = unit_p

implement {a} queue_is_nil (xs) =
  (unit_p() | deqarray_is_nil(xs))

implement {a} queue_is_full (xs) =
  (unit_p() | deqarray_is_full(xs))

implement {a} queue_remove (prf | xs) =
  let
    extern
    praxi not_nil {id:int} (p : ISNIL(id, false)) : [false] void
    
    prval () = not_nil(prf)
  in
    deqarray_takeout_atbeg<a>(xs)
  end

implement {a} queue_insert (prf | xs, x) =
  let
    extern
    praxi not_full {id:int} (p : ISFULL(id, false)) : [false] void
    
    prval () = not_full(prf)
    val () = deqarray_insert_atend<a>(xs, x)
  in end

implement {a} queue_make (cap) =
  deqarray_make_cap(i2sz(cap))

implement {a} queue_free (que) =
  deqarray_free_nil($UN.castvwtp0(que))

implement {a} channel_ref (chan) =
  let
    val @CHANNEL (ch) = chan
    val spin = unsafe_spin_vt2t(ch.spin)
    val (prf | ()) = spin_lock(spin)
    val () = ch.refcount := ch.refcount + 1
    val () = spin_unlock(prf | spin)
    prval () = fold@(chan)
  in
    $UN.castvwtp1{channel(a)}(chan)
  end

implement {a} channel_unref (chan) =
  let
    val @CHANNEL{l0,l1,l2,l3}(ch) = chan
    val spin = unsafe_spin_vt2t(ch.spin)
    val (prf | ()) = spin_lock(spin)
    val () = spin_unlock(prf | spin)
    val refcount = ch.refcount
  in
    if refcount <= 1 then
      let
        val que = $UN.castvwtp0{queue(a)}(ch.queue)
        val () = spin_vt_destroy(ch.spin)
        val () = mutex_vt_destroy(ch.mutex)
        val () = condvar_vt_destroy(ch.CVisNil)
        val () = condvar_vt_destroy(ch.CVisFull)
        val () = free@{l0,l1,l2,l3}(chan)
      in
        Some_vt(que)
      end
    else
      let
        val () = ch.refcount := refcount - 1
        prval () = fold@(chan)
        prval () = $UN.cast2void(chan)
      in
        None_vt()
      end
  end

implement channel_refcount {a} (chan) =
  let
    val @CHANNEL{l0,l1,l2,l3}(ch) = chan
    val refcount = ch.refcount
    prval () = fold@(chan)
  in
    refcount
  end

implement {a} channel_make (cap) =
  let
    extern
    praxi assert_agz() : [l:agz] void
    
    prval [l0:addr]() = assert_agz()
    prval [l1:addr]() = assert_agz()
    prval [l2:addr]() = assert_agz()
    prval [l3:addr]() = assert_agz()
    val chan = CHANNEL{l0,l1,l2,l3}(_)
    val+ CHANNEL (ch) = chan
    val () = ch.cap := cap
    val () = ch.refcount := 1
    
    local
      val x = spin_create_exn()
    in
      val () = ch.spin := unsafe_spin_t2vt(x)
    end
    
    local
      val x = mutex_create_exn()
    in
      val () = ch.mutex := unsafe_mutex_t2vt(x)
    end
    
    local
      val x = condvar_create_exn()
    in
      val () = ch.CVisNil := unsafe_condvar_t2vt(x)
    end
    
    local
      val x = condvar_create_exn()
    in
      val () = ch.CVisFull := unsafe_condvar_t2vt(x)
    end
    
    val () = ch.queue := $UN.castvwtp0{ptr}(queue_make<a>(cap))
  in
    (fold@(chan) ; chan)
  end

fun {a:vt@ype} channel_remove_helper(chan : !channel(a), xs : !queue(a) >> _) : a =
  let
    val+ CHANNEL{l0,l1,l2,l3}(ch) = chan
    val (prf | is_nil) = queue_is_nil(xs)
  in
    if is_nil then
      let
        prval (pfmut, fpf) = __assert() where
        { extern
          praxi __assert() : vtakeout0(locked_v(l1)) }
        val mutex = unsafe_mutex_vt2t(ch.mutex)
        val CVisNil = unsafe_condvar_vt2t(ch.CVisNil)
        val () = condvar_wait(pfmut | CVisNil, mutex)
        prval () = fpf(pfmut)
      in
        channel_remove_helper(chan, xs)
      end
    else
      let
        val is_full = queue_is_full(xs)
        val x_out = queue_remove(prf | xs)
        val () = if is_full.1 then
          condvar_broadcast(unsafe_condvar_vt2t(ch.CVisFull))
      in
        x_out
      end
  end

fun {a:vt@ype} channel_insert_helper(chan : !channel(a), xs : !queue(a) >> _, x : a) : void =
  let
    val+ CHANNEL{l0,l1,l2,l3}(ch) = chan
    val (prf | is_full) = queue_is_full(xs)
  in
    if is_full then
      let
        prval (pfmut, fpf) = __assert() where
        { extern
          praxi __assert() : vtakeout0(locked_v(l1)) }
        val mutex = unsafe_mutex_vt2t(ch.mutex)
        val CVisFull = unsafe_condvar_vt2t(ch.CVisFull)
        val () = condvar_wait(pfmut | CVisFull, mutex)
        prval () = fpf(pfmut)
      in
        channel_insert_helper(chan, xs, x)
      end
    else
      let
        val is_nil = queue_is_nil(xs)
        val () = queue_insert(prf | xs, x)
        val () = if is_nil.1 then
          condvar_broadcast(unsafe_condvar_vt2t(ch.CVisNil))
      in end
  end

implement {a} channel_insert (chan, x) =
  {
    val+ CHANNEL{l0,l1,l2,l3}(ch) = chan
    val mutex = unsafe_mutex_vt2t(ch.mutex)
    val (prf | ()) = mutex_lock(mutex)
    val xs = $UN.castvwtp0{queue(a)}((prf | ch.queue))
    val () = channel_insert_helper<a>(chan, xs, x)
    prval prf = $UN.castview0{locked_v(l1)}(xs)
    val () = mutex_unlock(prf | mutex)
  }

implement {a} channel_remove (chan) =
  let
    val+ CHANNEL{l0,l1,l2,l3}(ch) = chan
    val mutex = unsafe_mutex_vt2t(ch.mutex)
    val (prf | ()) = mutex_lock(mutex)
    val xs = $UN.castvwtp0{queue(a)}((prf | ch.queue))
    val x = channel_remove_helper<a>(chan, xs)
    prval prf = $UN.castview0{locked_v(l1)}(xs)
    val () = mutex_unlock(prf | mutex)
  in
    x
  end
