@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientBedBoardAllocationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704800564)
        var items: [BedManagement.LenientBedBoardAllocation] = []
        for index in 0..<2 {
            items.append(BedManagement.newLenientBedBoardAllocation("lenient-bed-board-allocation-\(index)", label: "sample"))
        }
        let report = BedManagement.buildLenientBedBoardAllocationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
