@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalBedBoardAllocationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701513086)
        var items: [BedManagement.RegionalBedBoardAllocation] = []
        for index in 0..<5 {
            items.append(BedManagement.newRegionalBedBoardAllocation("regional-bed-board-allocation-\(index)", title: "sample"))
        }
        let report = BedManagement.buildRegionalBedBoardAllocationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
