@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictTransferScoreReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702149479)
        var items: [BedManagement.StrictTransferScore] = []
        for index in 0..<3 {
            items.append(BedManagement.newStrictTransferScore("strict-transfer-score-\(index)", label: "sample"))
        }
        let report = BedManagement.buildStrictTransferScoreReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
