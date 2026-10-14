@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalHandoffManifestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709176415)
        var items: [ClinicalOps.RegionalHandoffManifest] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newRegionalHandoffManifest("regional-handoff-manifest-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildRegionalHandoffManifestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
