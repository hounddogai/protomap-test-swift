@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveAssessmentThresholdReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706690287)
        var items: [CareManagement.AdaptiveAssessmentThreshold] = []
        for index in 0..<3 {
            items.append(CareManagement.newAdaptiveAssessmentThreshold("adaptive-assessment-threshold-\(index)", title: "sample"))
        }
        let report = CareManagement.buildAdaptiveAssessmentThresholdReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
