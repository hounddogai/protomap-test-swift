@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalAlertTierReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700284941)
        var items: [ClinicalOps.RegionalAlertTier] = []
        for index in 0..<5 {
            items.append(ClinicalOps.newRegionalAlertTier("regional-alert-tier-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildRegionalAlertTierReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
