@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedBedBoardClaimReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707400833)
        var items: [BedManagement.WeightedBedBoardClaim] = []
        for index in 0..<2 {
            items.append(BedManagement.newWeightedBedBoardClaim("weighted-bed-board-claim-\(index)", name: "sample"))
        }
        let report = BedManagement.buildWeightedBedBoardClaimReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
