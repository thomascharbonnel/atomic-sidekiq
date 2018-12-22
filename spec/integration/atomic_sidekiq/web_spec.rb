RSpec.describe AtomicSidekiq::Web, type: :feature do
  it "display in-flight web" do
    visit "/in-flight"

    expect(status_code).to eq(200)
  end

  it "display recovered web" do
    visit "/recovered"

    expect(status_code).to eq(200)
  end

  describe "#in-flight" do
    context "when there are no inflight jobs" do
      it "show 0 total in-flight stats" do
        visit "/in-flight"

        expect(page).to have_css "table#inflight-stats"
        assert_selector "table#inflight-stats tbody" do |selector|
          rows = selector.all("tr")

          expect(rows.count).to eq(1)
          expect(rows.first.all("td")[0].text.to_i).to eq(0)
        end
      end

      it "show 0 extimated in-flight lost stats" do
        visit "/in-flight"

        expect(page).to have_css "table#inflight-stats"
        assert_selector "table#inflight-stats tbody" do |selector|
          rows = selector.all("tr")

          expect(rows.count).to eq(1)
          expect(rows.first.all("td")[1].text.to_i).to eq(0)
        end
      end

      it "show an empty inflight jobs table" do
        visit "/in-flight"

        expect(page).to have_css "table#inflight-jobs"
        assert_selector("table#inflight-jobs tbody tr", count: 0)
      end
    end

    context "when there is an inflight job enqueued" do
      let(:jid) { "12345-789-23456" }
      let(:expire_at) { Time.now.to_i + 60_000 }
      let(:job) { { class: "FakeJob", queue: "special", jid: jid, expire_at: expire_at }.to_json }
      let(:inflight_key) { "flight:special:#{jid}" }

      before do
        Sidekiq.redis { |conn| conn.set(inflight_key, job) }
      end

      it "show 1 total in-flight stats" do
        visit "/in-flight"

        expect(page).to have_css "table#inflight-stats"
        assert_selector "table#inflight-stats tbody" do |selector|
          rows = selector.all("tr")

          expect(rows.count).to eq(1)
          expect(rows.first.all("td")[0].text.to_i).to eq(1)
        end
      end

      it "show 1 extimated in-flight lost stats" do
        visit "/in-flight"

        expect(page).to have_css "table#inflight-stats"
        assert_selector "table#inflight-stats tbody" do |selector|
          rows = selector.all("tr")

          expect(rows.count).to eq(1)
          expect(rows.first.all("td")[1].text.to_i).to eq(1)
        end
      end

      it "lists the inflight jobs" do
        visit "/in-flight"

        expect(page).to have_css "table#inflight-jobs"
        assert_selector("table#inflight-jobs tbody tr", count: 1)
      end
    end
  end
end
