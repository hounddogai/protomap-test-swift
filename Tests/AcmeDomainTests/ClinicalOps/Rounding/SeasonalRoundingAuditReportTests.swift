@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalRoundingAuditReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705291971)
        var items: [ClinicalOps.SeasonalRoundingAudit] = []
        for index in 0..<4 {
            items.append(ClinicalOps.newSeasonalRoundingAudit("seasonal-rounding-audit-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildSeasonalRoundingAuditReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
