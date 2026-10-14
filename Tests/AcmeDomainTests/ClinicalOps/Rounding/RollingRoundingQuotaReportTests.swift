@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingRoundingQuotaReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704638024)
        var items: [ClinicalOps.RollingRoundingQuota] = []
        for index in 0..<6 {
            items.append(ClinicalOps.newRollingRoundingQuota("rolling-rounding-quota-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildRollingRoundingQuotaReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
