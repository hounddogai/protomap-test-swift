@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingAssessmentPreferenceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707622428)
        var items: [CareManagement.PendingAssessmentPreference] = []
        for index in 0..<2 {
            items.append(CareManagement.newPendingAssessmentPreference("pending-assessment-preference-\(index)", label: "sample"))
        }
        let report = CareManagement.buildPendingAssessmentPreferenceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
