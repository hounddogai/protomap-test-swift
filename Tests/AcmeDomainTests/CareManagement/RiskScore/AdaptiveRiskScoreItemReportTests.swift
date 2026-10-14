@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveRiskScoreItemReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704523067)
        var items: [CareManagement.AdaptiveRiskScoreItem] = []
        for index in 0..<3 {
            items.append(CareManagement.newAdaptiveRiskScoreItem("adaptive-risk-score-item-\(index)", name: "sample"))
        }
        let report = CareManagement.buildAdaptiveRiskScoreItemReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
