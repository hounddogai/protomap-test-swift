@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultShiftAllocationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702613557)
        var items: [Staffing.DefaultShiftAllocation] = []
        for index in 0..<5 {
            items.append(Staffing.newDefaultShiftAllocation("default-shift-allocation-\(index)", name: "sample"))
        }
        let report = Staffing.buildDefaultShiftAllocationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
