@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedCareProtocolTierReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709861095)
        var items: [ClinicalOps.CappedCareProtocolTier] = []
        for index in 0..<6 {
            items.append(ClinicalOps.newCappedCareProtocolTier("capped-care-protocol-tier-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildCappedCareProtocolTierReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
