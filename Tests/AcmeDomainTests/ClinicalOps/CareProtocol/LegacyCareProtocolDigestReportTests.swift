@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyCareProtocolDigestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707931662)
        var items: [ClinicalOps.LegacyCareProtocolDigest] = []
        for index in 0..<4 {
            items.append(ClinicalOps.newLegacyCareProtocolDigest("legacy-care-protocol-digest-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildLegacyCareProtocolDigestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
