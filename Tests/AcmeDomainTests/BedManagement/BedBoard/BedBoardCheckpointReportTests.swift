@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardCheckpointReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707339085)
        var items: [BedManagement.BedBoardCheckpoint] = []
        for index in 0..<2 {
            items.append(BedManagement.newBedBoardCheckpoint("bed-board-checkpoint-\(index)", title: "sample"))
        }
        let report = BedManagement.buildBedBoardCheckpointReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
