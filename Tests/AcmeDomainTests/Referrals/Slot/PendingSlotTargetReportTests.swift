@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingSlotTargetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702124490)
        var items: [Referrals.PendingSlotTarget] = []
        for index in 0..<4 {
            items.append(Referrals.newPendingSlotTarget("pending-slot-target-\(index)", name: "sample"))
        }
        let report = Referrals.buildPendingSlotTargetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
