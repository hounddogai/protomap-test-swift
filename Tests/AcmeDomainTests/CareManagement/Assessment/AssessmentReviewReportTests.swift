@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentReviewReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703763535)
        var items: [CareManagement.AssessmentReview] = []
        for index in 0..<6 {
            items.append(CareManagement.newAssessmentReview("assessment-review-\(index)", title: "sample"))
        }
        let report = CareManagement.buildAssessmentReviewReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
