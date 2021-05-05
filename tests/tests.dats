#include "ats-channel.hats"

staload $CHANNEL

implement main(argc, argv) = 0 where {
    val ch = channel_make<int>(1)
    val ch2 = channel_ref(ch)
    val () = channel_insert(ch, 3)
    val a = channel_remove<int>(ch)
    val () = println!(a)
    val-~None_vt() = channel_unref(ch2)
    val-~Some_vt(q) = channel_unref(ch)
    val () = queue_free(q)
}
