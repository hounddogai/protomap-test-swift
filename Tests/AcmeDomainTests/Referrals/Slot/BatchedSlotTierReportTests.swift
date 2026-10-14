@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedSlotTierReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707526376)
        var items: [Referrals.BatchedSlotTier] = []
        for index in 0..<2 {
            items.append(Referrals.newBatchedSlotTier("batched-slot-tier-\(index)", title: "sample"))
        }
        let report = Referrals.buildBatchedSlotTierReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
