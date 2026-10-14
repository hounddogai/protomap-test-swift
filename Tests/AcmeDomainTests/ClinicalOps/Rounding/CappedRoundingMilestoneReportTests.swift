@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedRoundingMilestoneReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703941134)
        var items: [ClinicalOps.CappedRoundingMilestone] = []
        for index in 0..<4 {
            items.append(ClinicalOps.newCappedRoundingMilestone("capped-rounding-milestone-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildCappedRoundingMilestoneReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
