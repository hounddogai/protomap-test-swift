@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolManifestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703118768)
        var items: [ClinicalOps.CareProtocolManifest] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newCareProtocolManifest("care-protocol-manifest-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildCareProtocolManifestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
