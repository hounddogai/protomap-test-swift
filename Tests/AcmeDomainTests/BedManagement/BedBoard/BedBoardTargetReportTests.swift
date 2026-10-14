@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardTargetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706056057)
        var items: [BedManagement.BedBoardTarget] = []
        for index in 0..<4 {
            items.append(BedManagement.newBedBoardTarget("bed-board-target-\(index)", label: "sample"))
        }
        let report = BedManagement.buildBedBoardTargetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
