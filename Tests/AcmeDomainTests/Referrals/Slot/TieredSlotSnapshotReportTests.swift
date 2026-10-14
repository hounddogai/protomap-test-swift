@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredSlotSnapshotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708309713)
        var items: [Referrals.TieredSlotSnapshot] = []
        for index in 0..<2 {
            items.append(Referrals.newTieredSlotSnapshot("tiered-slot-snapshot-\(index)", name: "sample"))
        }
        let report = Referrals.buildTieredSlotSnapshotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
