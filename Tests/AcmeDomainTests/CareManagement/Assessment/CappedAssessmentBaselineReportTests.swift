@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedAssessmentBaselineReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703512573)
        var items: [CareManagement.CappedAssessmentBaseline] = []
        for index in 0..<2 {
            items.append(CareManagement.newCappedAssessmentBaseline("capped-assessment-baseline-\(index)", label: "sample"))
        }
        let report = CareManagement.buildCappedAssessmentBaselineReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
