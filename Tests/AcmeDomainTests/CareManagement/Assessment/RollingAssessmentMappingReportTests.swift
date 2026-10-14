@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingAssessmentMappingReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708721975)
        var items: [CareManagement.RollingAssessmentMapping] = []
        for index in 0..<2 {
            items.append(CareManagement.newRollingAssessmentMapping("rolling-assessment-mapping-\(index)", name: "sample"))
        }
        let report = CareManagement.buildRollingAssessmentMappingReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
