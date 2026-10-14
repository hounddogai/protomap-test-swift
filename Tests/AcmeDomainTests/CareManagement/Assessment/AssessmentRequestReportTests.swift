@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentRequestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707942442)
        var items: [CareManagement.AssessmentRequest] = []
        for index in 0..<4 {
            items.append(CareManagement.newAssessmentRequest("assessment-request-\(index)", title: "sample"))
        }
        let report = CareManagement.buildAssessmentRequestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
