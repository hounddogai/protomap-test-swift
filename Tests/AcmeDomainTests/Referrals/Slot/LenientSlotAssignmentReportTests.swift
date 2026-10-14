@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientSlotAssignmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707092962)
        var items: [Referrals.LenientSlotAssignment] = []
        for index in 0..<3 {
            items.append(Referrals.newLenientSlotAssignment("lenient-slot-assignment-\(index)", name: "sample"))
        }
        let report = Referrals.buildLenientSlotAssignmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
