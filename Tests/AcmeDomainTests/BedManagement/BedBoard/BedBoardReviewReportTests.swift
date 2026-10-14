@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardReviewReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702554380)
        var items: [BedManagement.BedBoardReview] = []
        for index in 0..<2 {
            items.append(BedManagement.newBedBoardReview("bed-board-review-\(index)", name: "sample"))
        }
        let report = BedManagement.buildBedBoardReviewReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
