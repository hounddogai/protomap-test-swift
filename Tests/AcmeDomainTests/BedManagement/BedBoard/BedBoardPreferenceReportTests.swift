@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardPreferenceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702644347)
        var items: [BedManagement.BedBoardPreference] = []
        for index in 0..<4 {
            items.append(BedManagement.newBedBoardPreference("bed-board-preference-\(index)", title: "sample"))
        }
        let report = BedManagement.buildBedBoardPreferenceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
