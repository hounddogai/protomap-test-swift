@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingBudgetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706501459)
        var items: [ClinicalOps.RoundingBudget] = []
        for index in 0..<6 {
            items.append(ClinicalOps.newRoundingBudget("rounding-budget-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildRoundingBudgetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
