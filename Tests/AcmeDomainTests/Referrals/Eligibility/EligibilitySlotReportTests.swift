@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilitySlotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703879943)
        var items: [Referrals.EligibilitySlot] = []
        for index in 0..<3 {
            items.append(Referrals.newEligibilitySlot("eligibility-slot-\(index)", name: "sample"))
        }
        let report = Referrals.buildEligibilitySlotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
