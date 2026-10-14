@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalFollowUpBaselineReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709841195)
        var items: [Referrals.GlobalFollowUpBaseline] = []
        for index in 0..<5 {
            items.append(Referrals.newGlobalFollowUpBaseline("global-follow-up-baseline-\(index)", label: "sample"))
        }
        let report = Referrals.buildGlobalFollowUpBaselineReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
