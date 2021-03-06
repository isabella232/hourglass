describe SendTimerReminders do
  let(:today) { Date.current }

  it "sends a reminder for any user who hasn't started a timer yet today" do
    user_1 = create(:user, email: "john@example.com")
    user_2 = create(:user, email: "jane@example.com")
    day_1 = create(:day, {
      user: user_1,
      date: today,
      client_hours: 0,
      internal_hours: 1,
      pto: false
    })
    day_2 = create(:day, {
      user: user_2,
      date: today,
      client_hours: 0,
      internal_hours: 0,
      pto: false
    })

    SendTimerReminders.call(time_zone: user_1.time_zone)

    expect(mailbox_for(user_1.email)).to be_empty
    expect(day_1.reload.timer_reminder_sent).to be_falsey

    open_last_email_for(user_2.email)
    expect(current_email).to have_i18n_subject_for("timer_reminder")
    expect(day_2.reload.timer_reminder_sent).to be_truthy
  end

  it "only reminds users who have passed the time threshold in their time zone" do
    user_1 = create(:user, time_zone: "Cairo")
    user_2 = create(:user, time_zone: "Alaska")

    day_1 = create(:day, {
      user: user_1,
      date: today,
      client_hours: 0,
      internal_hours: 0,
      pto: false
    })

    day_2 = create(:day, {
      user: user_2,
      date: today,
      client_hours: 0,
      internal_hours: 0,
      pto: false
    })

    SendTimerReminders.call(time_zone: user_2.time_zone)

    expect(mailbox_for(user_1.email)).to be_empty
    expect(day_1.reload.timer_reminder_sent).to be_falsey

    open_last_email_for(user_2.email)
    expect(current_email).to have_i18n_subject_for("timer_reminder")
    expect(day_2.reload.timer_reminder_sent).to be_truthy
  end

  it "only sends one reminder per day" do
    user = create(:user)
    create(:day, {
      user: user,
      date: today,
      client_hours: 0,
      internal_hours: 0,
      pto: false
    })

    expect {
      SendTimerReminders.call(time_zone: user.time_zone)
    }.to change {
      mailbox_for(user.email).size
    }.from(0).to(1)

    expect {
      SendTimerReminders.call(time_zone: user.time_zone)
    }.not_to change {
      mailbox_for(user.email).size
    }
  end

  it "doesn't send a reminder on a PTO day" do
    user = create(:user)
    create(:day, {
      user: user,
      date: today,
      client_hours: 0,
      internal_hours: 0,
      pto: true
    })

    expect {
      SendTimerReminders.call(time_zone: user.time_zone)
    }.not_to change {
      mailbox_for(user.email).size
    }
  end

  it "doesn't send a reminder if it's not a workday for that user" do
    user_1 = create(:user, email: "john@example.com")
    user_2 = create(:user, email: "jane@example.com")
    create(:day, {
      user: user_1,
      date: today,
      client_hours: 0,
      internal_hours: 0,
      pto: false,
      workday: true
    })
    create(:day, {
      user: user_2,
      date: today,
      client_hours: 0,
      internal_hours: 0,
      pto: false,
      workday: false
    })

    SendTimerReminders.call(time_zone: user_1.time_zone)

    expect(mailbox_for(user_1.email).size).to eq(1)
    expect(mailbox_for(user_2.email).size).to eq(0)
  end
end
