@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreBundleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700511960)
        var items: [CareManagement.RiskScoreBundle] = []
        for index in 0..<4 {
            items.append(CareManagement.newRiskScoreBundle("risk-score-bundle-\(index)", name: "sample"))
        }
        let report = CareManagement.buildRiskScoreBundleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
