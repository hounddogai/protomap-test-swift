@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalRoundingEstimateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707234203)
        var items: [ClinicalOps.SeasonalRoundingEstimate] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newSeasonalRoundingEstimate("seasonal-rounding-estimate-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildSeasonalRoundingEstimateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
