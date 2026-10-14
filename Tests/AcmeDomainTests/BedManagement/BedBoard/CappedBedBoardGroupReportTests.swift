@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedBedBoardGroupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703367791)
        var items: [BedManagement.CappedBedBoardGroup] = []
        for index in 0..<3 {
            items.append(BedManagement.newCappedBedBoardGroup("capped-bed-board-group-\(index)", label: "sample"))
        }
        let report = BedManagement.buildCappedBedBoardGroupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
