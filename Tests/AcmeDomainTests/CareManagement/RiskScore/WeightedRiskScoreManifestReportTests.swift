@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedRiskScoreManifestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708156021)
        var items: [CareManagement.WeightedRiskScoreManifest] = []
        for index in 0..<2 {
            items.append(CareManagement.newWeightedRiskScoreManifest("weighted-risk-score-manifest-\(index)", label: "sample"))
        }
        let report = CareManagement.buildWeightedRiskScoreManifestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
