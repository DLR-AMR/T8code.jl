@testset "test refcount" begin
    @testset "test refcount init" begin
        rc_ref = Ref(t8_refcount_t(-1, -1))
        t8_refcount_init(rc_ref)

        @test rc_ref[].refcount == 1

        @test T8code.Libt8.sc_refcount_is_active(rc_ref) == 1
        @test T8code.Libt8.sc_refcount_is_last(rc_ref) == 1
        @test T8code.Libt8.sc_refcount_unref(rc_ref) == 1
    end

    @testset "test refcount init" begin
        rc_ptr = t8_refcount_new()
        rc_ref = unsafe_wrap(Array, rc_ptr, 1)

        @test rc_ref[].refcount == 1

        @test T8code.Libt8.sc_refcount_is_active(rc_ptr) == 1
        @test T8code.Libt8.sc_refcount_is_last(rc_ptr) == 1
        @test T8code.Libt8.sc_refcount_unref(rc_ptr) == 1

        t8_refcount_destroy(rc_ptr)
    end

    @testset "test refcount IsActive" begin
        rc_ref = Ref(t8_refcount_t(-1, -1))
        t8_refcount_init(rc_ref)

        @test rc_ref[].refcount == 1

        @test T8code.Libt8.sc_refcount_is_active(rc_ref) == 1
        @test T8code.Libt8.sc_refcount_unref(rc_ref) == 1
        @test T8code.Libt8.sc_refcount_is_active(rc_ref) == 0
    end

    @testset "test refcount IsLast" begin
        rc_ref = Ref(t8_refcount_t(-1, -1))
        t8_refcount_init(rc_ref)

        @test T8code.Libt8.sc_refcount_is_last(rc_ref) == 1
        T8code.Libt8.sc_refcount_ref(rc_ref)
        @test T8code.Libt8.sc_refcount_is_last(rc_ref) == 0

        @test T8code.Libt8.sc_refcount_unref(rc_ref) == 0
        @test T8code.Libt8.sc_refcount_unref(rc_ref) == 1
    end

    @testset "test refcount RefUnref" begin
        rc_ref = Ref(t8_refcount_t(-1, -1))
        t8_refcount_init(rc_ref)

        for value in 1:9
            @test rc_ref[].refcount == value
            T8code.Libt8.sc_refcount_ref(rc_ref)
        end

        @test rc_ref[].refcount == 10

        for value in 9:-1:1
            @test T8code.Libt8.sc_refcount_unref(rc_ref) == 0
            @test rc_ref[].refcount == value
        end

        @test T8code.Libt8.sc_refcount_unref(rc_ref) == 1
    end
end
