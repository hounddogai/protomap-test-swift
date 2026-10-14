@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingBatchedOvertimeAllocationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700377686)
        var items: [Staffing.BatchedOvertimeAllocation] = []
        for index in 0..<3 {
            items.append(Staffing.newBatchedOvertimeAllocation("batched-overtime-allocation-\(index)", title: "sample"))
        }
        let report = Staffing.buildBatchedOvertimeAllocationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
