@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultRoundingManifestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702288698)
        var items: [ClinicalOps.DefaultRoundingManifest] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newDefaultRoundingManifest("default-rounding-manifest-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildDefaultRoundingManifestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
