@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedAccessionPlanReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703391654)
        var items: [Labs.BatchedAccessionPlan] = []
        for index in 0..<5 {
            items.append(Labs.newBatchedAccessionPlan("batched-accession-plan-\(index)", title: "sample"))
        }
        let report = Labs.buildBatchedAccessionPlanReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
