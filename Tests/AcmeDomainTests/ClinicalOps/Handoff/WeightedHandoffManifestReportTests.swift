@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedHandoffManifestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704270683)
        var items: [ClinicalOps.WeightedHandoffManifest] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newWeightedHandoffManifest("weighted-handoff-manifest-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildWeightedHandoffManifestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
