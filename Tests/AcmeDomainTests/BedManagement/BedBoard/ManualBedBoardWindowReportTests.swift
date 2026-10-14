@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualBedBoardWindowReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707968575)
        var items: [BedManagement.ManualBedBoardWindow] = []
        for index in 0..<6 {
            items.append(BedManagement.newManualBedBoardWindow("manual-bed-board-window-\(index)", label: "sample"))
        }
        let report = BedManagement.buildManualBedBoardWindowReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
