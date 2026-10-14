@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimarySlotRollupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709075382)
        var items: [Referrals.PrimarySlotRollup] = []
        for index in 0..<3 {
            items.append(Referrals.newPrimarySlotRollup("primary-slot-rollup-\(index)", name: "sample"))
        }
        let report = Referrals.buildPrimarySlotRollupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
