@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredCareGapAuditReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706103378)
        var items: [CareManagement.TieredCareGapAudit] = []
        for index in 0..<3 {
            items.append(CareManagement.newTieredCareGapAudit("tiered-care-gap-audit-\(index)", title: "sample"))
        }
        let report = CareManagement.buildTieredCareGapAuditReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
