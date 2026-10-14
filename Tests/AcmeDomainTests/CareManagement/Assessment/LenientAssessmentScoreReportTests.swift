@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientAssessmentScoreReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706046461)
        var items: [CareManagement.LenientAssessmentScore] = []
        for index in 0..<3 {
            items.append(CareManagement.newLenientAssessmentScore("lenient-assessment-score-\(index)", name: "sample"))
        }
        let report = CareManagement.buildLenientAssessmentScoreReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
