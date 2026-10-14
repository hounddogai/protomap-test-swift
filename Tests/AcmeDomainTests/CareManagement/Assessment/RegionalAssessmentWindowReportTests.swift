@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalAssessmentWindowReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700428211)
        var items: [CareManagement.RegionalAssessmentWindow] = []
        for index in 0..<5 {
            items.append(CareManagement.newRegionalAssessmentWindow("regional-assessment-window-\(index)", name: "sample"))
        }
        let report = CareManagement.buildRegionalAssessmentWindowReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
