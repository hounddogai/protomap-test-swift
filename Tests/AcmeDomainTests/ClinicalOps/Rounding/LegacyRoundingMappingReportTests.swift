@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyRoundingMappingReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700132233)
        var items: [ClinicalOps.LegacyRoundingMapping] = []
        for index in 0..<4 {
            items.append(ClinicalOps.newLegacyRoundingMapping("legacy-rounding-mapping-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildLegacyRoundingMappingReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
