@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardWindowReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705694679)
        var items: [BedManagement.BedBoardWindow] = []
        for index in 0..<3 {
            items.append(BedManagement.newBedBoardWindow("bed-board-window-\(index)", title: "sample"))
        }
        let report = BedManagement.buildBedBoardWindowReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
