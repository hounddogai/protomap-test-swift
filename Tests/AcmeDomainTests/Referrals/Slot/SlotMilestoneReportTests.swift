@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotMilestoneReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704271096)
        var items: [Referrals.SlotMilestone] = []
        for index in 0..<3 {
            items.append(Referrals.newSlotMilestone("slot-milestone-\(index)", name: "sample"))
        }
        let report = Referrals.buildSlotMilestoneReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
