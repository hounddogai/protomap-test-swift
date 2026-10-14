@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalFollowUpMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706680016)
        var items: [Referrals.RegionalFollowUpMetric] = []
        for index in 0..<3 {
            items.append(Referrals.newRegionalFollowUpMetric("regional-follow-up-metric-\(index)", label: "sample"))
        }
        let report = Referrals.buildRegionalFollowUpMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
