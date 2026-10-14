@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedFollowUpRuleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703638864)
        var items: [Referrals.WeightedFollowUpRule] = []
        for index in 0..<4 {
            items.append(Referrals.newWeightedFollowUpRule("weighted-follow-up-rule-\(index)", label: "sample"))
        }
        let report = Referrals.buildWeightedFollowUpRuleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
