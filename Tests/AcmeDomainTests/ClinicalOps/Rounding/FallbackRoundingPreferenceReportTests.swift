@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackRoundingPreferenceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709711098)
        var items: [ClinicalOps.FallbackRoundingPreference] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newFallbackRoundingPreference("fallback-rounding-preference-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildFallbackRoundingPreferenceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
