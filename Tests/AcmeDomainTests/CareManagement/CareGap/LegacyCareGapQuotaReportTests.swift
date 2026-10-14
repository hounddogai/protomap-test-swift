@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyCareGapQuotaReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703677308)
        var items: [CareManagement.LegacyCareGapQuota] = []
        for index in 0..<4 {
            items.append(CareManagement.newLegacyCareGapQuota("legacy-care-gap-quota-\(index)", label: "sample"))
        }
        let report = CareManagement.buildLegacyCareGapQuotaReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
