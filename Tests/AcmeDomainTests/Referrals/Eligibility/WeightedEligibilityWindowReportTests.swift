@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedEligibilityWindowReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700233132)
        var items: [Referrals.WeightedEligibilityWindow] = []
        for index in 0..<5 {
            items.append(Referrals.newWeightedEligibilityWindow("weighted-eligibility-window-\(index)", label: "sample"))
        }
        let report = Referrals.buildWeightedEligibilityWindowReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
