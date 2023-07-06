module Schedule
export overall 

using ..Basic, ..Rules, ..Boxes
using Catlab
using AlgebraicRewriting



#############
# Schedules #
#############

"""Process of picking initial infected person"""
function initial_infection_sched() 
  mk_sched((trace_arg=Symbol("•"),), (init=Symbol(""),), Name,
           (avg=if_close_avg(), quer=query_vertices(), 
           rw=infectmild(), w=Weaken(create(Av)), fail=Fail(I)), quote 
    q1,q2,q3 = quer(init,trace_arg,)
    fail([q1,q3])
    avg1, avg2 = avg(q2)
    inf1 = rw(avg1)
    return (avg2, w(inf1))
  end)
end

ia_update() = mk_sched((;),(init=:Ia,),Name,(
  over_8=n_days_sick(:a,8), 
  coin=const_cond([0.09,0.91], Name["Ia"]),
  inc=increment(:a), 
  rec=recover(:a), 
  wi=Weaken(create(Name["Ia"])), 
  wr=Weaken(create(Name["R"]))), 
  quote
    o8, b8 = over_8(inc(init))
    win_coin, lose_coin = coin(o8)
    recovered = rec(win_coin)
    do_nothing = [lose_coin, b8]
    return [wr(recovered), wi(do_nothing)]
end)

im_update() = mk_sched((;),(init=:Im,),Name,(
  over_20=n_days_sick(:m,20), 
  over_10=n_days_sick(:m,10), 
  coin=const_cond([0.2,0.8], Name["Im"]),
  symptom_day=is_symptom_day(:m),
  show_symptoms=shows_symptoms(:m),
  rec_flip=recoveryFlip(),
  inc=increment(:m), 
  rec=recover(:m), 
  iso=isolate(),
  wi=Weaken(create(Name["Im"])), 
  wr=Weaken(create(Name["R"]))), 
  quote
    sday, nsday = symptom_day(inc(init))
    rep,no_rep = coin(sday)
    iso_symptoms = iso([rep,no_rep])
    o20, b20 = over_20(nsday)
    o10, b10 = over_10(b20)
    can_recup, cant_recup = show_symptoms(o10)
    recup, norecup = rec_flip(can_recup)
    recupped = rec([recup, o20])
    return [wr(recupped), wi([iso_symptoms, b10, cant_recup, norecup])]
end)


"""
Currently only treating infected asymptomatic and infected mild
"""
inf_update() = 
  agent(ia_update();n=:Ia, ret=SIRD()) ⋅ agent(im_update();n=:I, ret=SIRD())


inf_infect() =  mk_sched((;),(init=Symbol("m-s"),),Name,(
  wgt=eweight(),
  i=infectmild(), 
  we=Weaken(create(Name["m-s"])),
  wv=Weaken(homomorphism(Name["•"],Name["m-s"])),
  w=Weaken(create(Name["•"]))),
  quote
    inf, noinf = wgt(init)
    return [we(noinf), w(i(wv(inf)))]
end)


"""
Currently ignoring 
 - "action days"
 - case count (global counter)

"""

overall(n_days::Int) = for_schedule(inf_update() ⋅ agent(inf_infect();ret=SIRD()), n_days)


end # module
