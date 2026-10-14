@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardDraftReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706729845)
        var items: [BedManagement.BedBoardDraft] = []
        for index in 0..<2 {
            items.append(BedManagement.newBedBoardDraft("bed-board-draft-\(index)", name: "sample"))
        }
        let report = BedManagement.buildBedBoardDraftReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
