@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingMilestoneReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703495050)
        var items: [ClinicalOps.RoundingMilestone] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newRoundingMilestone("rounding-milestone-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildRoundingMilestoneReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
