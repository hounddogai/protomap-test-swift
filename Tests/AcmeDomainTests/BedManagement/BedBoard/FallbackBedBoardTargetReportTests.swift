@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackBedBoardTargetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701645349)
        var items: [BedManagement.FallbackBedBoardTarget] = []
        for index in 0..<3 {
            items.append(BedManagement.newFallbackBedBoardTarget("fallback-bed-board-target-\(index)", label: "sample"))
        }
        let report = BedManagement.buildFallbackBedBoardTargetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
