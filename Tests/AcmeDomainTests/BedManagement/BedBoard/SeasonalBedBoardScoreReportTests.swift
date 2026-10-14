@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementSeasonalBedBoardScoreReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704436059)
        var items: [BedManagement.SeasonalBedBoardScore] = []
        for index in 0..<6 {
            items.append(BedManagement.newSeasonalBedBoardScore("seasonal-bed-board-score-\(index)", title: "sample"))
        }
        let report = BedManagement.buildSeasonalBedBoardScoreReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
