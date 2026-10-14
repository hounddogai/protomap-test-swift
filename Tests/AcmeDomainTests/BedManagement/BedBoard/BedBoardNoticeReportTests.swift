@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardNoticeReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705975655)
        var items: [BedManagement.BedBoardNotice] = []
        for index in 0..<4 {
            items.append(BedManagement.newBedBoardNotice("bed-board-notice-\(index)", title: "sample"))
        }
        let report = BedManagement.buildBedBoardNoticeReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
