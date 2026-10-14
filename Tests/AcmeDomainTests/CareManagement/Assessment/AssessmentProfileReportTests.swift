@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentProfileReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701439283)
        var items: [CareManagement.AssessmentProfile] = []
        for index in 0..<5 {
            items.append(CareManagement.newAssessmentProfile("assessment-profile-\(index)", name: "sample"))
        }
        let report = CareManagement.buildAssessmentProfileReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
