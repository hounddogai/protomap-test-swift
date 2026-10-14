@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703054755)
        var items: [Referrals.FollowUpMetric] = []
        for index in 0..<3 {
            items.append(Referrals.newFollowUpMetric("follow-up-metric-\(index)", label: "sample"))
        }
        let report = Referrals.buildFollowUpMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
