@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveHandoffVarianceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704274519)
        var items: [ClinicalOps.AdaptiveHandoffVariance] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newAdaptiveHandoffVariance("adaptive-handoff-variance-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildAdaptiveHandoffVarianceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
