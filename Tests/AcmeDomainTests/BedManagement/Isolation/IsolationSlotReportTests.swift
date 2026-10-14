@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationSlotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706527137)
        var items: [BedManagement.IsolationSlot] = []
        for index in 0..<6 {
            items.append(BedManagement.newIsolationSlot("isolation-slot-\(index)", label: "sample"))
        }
        let report = BedManagement.buildIsolationSlotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
