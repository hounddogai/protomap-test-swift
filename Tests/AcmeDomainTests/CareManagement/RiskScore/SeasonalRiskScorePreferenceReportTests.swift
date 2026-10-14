@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalRiskScorePreferenceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707037823)
        var items: [CareManagement.SeasonalRiskScorePreference] = []
        for index in 0..<5 {
            items.append(CareManagement.newSeasonalRiskScorePreference("seasonal-risk-score-preference-\(index)", title: "sample"))
        }
        let report = CareManagement.buildSeasonalRiskScorePreferenceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
