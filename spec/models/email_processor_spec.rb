describe EmailProcessor do
  describe "#process" do
    it "creates an entry based on the email" do
      user = create(:user)
      email = create(
        :griddler_email,
        from: { email: user.email },
        body: "I am great"
      )

      EmailProcessor.new(email).process

      expect(user.newest_entry.body).to eq("I am great")
    end

    it "creates an entry even if the email address is uppercase" do
      user = create(:user)
      email = create(
        :griddler_email,
        from: { email: user.email.upcase },
        body: "I am great"
      )

      EmailProcessor.new(email).process

      expect(user.newest_entry.body).to eq("I am great")
    end

    context "when a user can't be found" do
      it "raises an exception" do
        user = create(:user)
        email = create(:griddler_email, from: { email: "nobody@example.com" })

        expect do
          EmailProcessor.new(email).process
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the entry can't be created" do
      it "raises an exception" do
        user = create(:user)
        email = create(:griddler_email, from: { email: user.email }, body: nil)

        expect do
          EmailProcessor.new(email).process
        end.to raise_error(ActiveRecord::ActiveRecordError)
      end
    end

    it "sets the entry date to today's date in the user's time zone" do
      Timecop.freeze(2014, 1, 1, 20) do # 8 PM UTC
        user = create(:user, time_zone: "Guam") # UTC+10
        email = create(:griddler_email, from: { email: user.email })

        EmailProcessor.new(email).process

        expect(user.newest_entry.date).to eq(Date.new(2014, 1, 2))
      end
    end

    context "when the entry is a response to yesterday's email" do
      it "sets the entry date to yesterday's date in the user's time zone" do
        yesterday = Time.utc(2014, 1, 1, 20) # 8 PM UTC
        user = create(:user, time_zone: "Guam") # UTC+10
        email = create(
          :griddler_email,
          from: { email: user.email },
          subject: "Re: #{PromptMailer::Subject.new(user, yesterday)}"
        )

        EmailProcessor.new(email).process

        expect(user.newest_entry.date).to eq(Date.new(2014, 1, 2))
      end
    end
  end
end
