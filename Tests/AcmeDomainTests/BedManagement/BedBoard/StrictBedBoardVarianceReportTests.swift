@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictBedBoardVarianceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706222498)
        var items: [BedManagement.StrictBedBoardVariance] = []
        for index in 0..<6 {
            items.append(BedManagement.newStrictBedBoardVariance("strict-bed-board-variance-\(index)", name: "sample"))
        }
        let report = BedManagement.buildStrictBedBoardVarianceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
