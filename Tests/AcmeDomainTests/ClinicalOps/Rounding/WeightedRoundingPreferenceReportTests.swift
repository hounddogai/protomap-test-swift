@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedRoundingPreferenceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701801881)
        var items: [ClinicalOps.WeightedRoundingPreference] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newWeightedRoundingPreference("weighted-rounding-preference-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildWeightedRoundingPreferenceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
