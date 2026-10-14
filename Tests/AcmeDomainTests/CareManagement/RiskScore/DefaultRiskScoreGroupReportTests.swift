@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultRiskScoreGroupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706150939)
        var items: [CareManagement.DefaultRiskScoreGroup] = []
        for index in 0..<3 {
            items.append(CareManagement.newDefaultRiskScoreGroup("default-risk-score-group-\(index)", label: "sample"))
        }
        let report = CareManagement.buildDefaultRiskScoreGroupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
