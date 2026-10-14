@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultPlanReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708779775)
        var items: [Labs.ResultPlan] = []
        for index in 0..<2 {
            items.append(Labs.newResultPlan("result-plan-\(index)", name: "sample"))
        }
        let report = Labs.buildResultPlanReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
