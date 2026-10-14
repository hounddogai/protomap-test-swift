@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackBedBoardVarianceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701157460)
        var items: [BedManagement.FallbackBedBoardVariance] = []
        for index in 0..<5 {
            items.append(BedManagement.newFallbackBedBoardVariance("fallback-bed-board-variance-\(index)", name: "sample"))
        }
        let report = BedManagement.buildFallbackBedBoardVarianceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
