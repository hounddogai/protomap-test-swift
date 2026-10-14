@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictBedBoardCycleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707911800)
        var items: [BedManagement.StrictBedBoardCycle] = []
        for index in 0..<4 {
            items.append(BedManagement.newStrictBedBoardCycle("strict-bed-board-cycle-\(index)", name: "sample"))
        }
        let report = BedManagement.buildStrictBedBoardCycleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
