@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertTierReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701877981)
        var items: [ClinicalOps.AlertTier] = []
        for index in 0..<4 {
            items.append(ClinicalOps.newAlertTier("alert-tier-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildAlertTierReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
