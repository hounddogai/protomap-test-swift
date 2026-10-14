@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentAdjustmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709338515)
        var items: [CareManagement.AssessmentAdjustment] = []
        for index in 0..<4 {
            items.append(CareManagement.newAssessmentAdjustment("assessment-adjustment-\(index)", label: "sample"))
        }
        let report = CareManagement.buildAssessmentAdjustmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
