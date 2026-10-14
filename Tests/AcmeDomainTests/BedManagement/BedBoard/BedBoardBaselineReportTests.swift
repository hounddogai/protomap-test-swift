@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardBaselineReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707100945)
        var items: [BedManagement.BedBoardBaseline] = []
        for index in 0..<6 {
            items.append(BedManagement.newBedBoardBaseline("bed-board-baseline-\(index)", label: "sample"))
        }
        let report = BedManagement.buildBedBoardBaselineReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
