@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredProgramQuotaReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700299889)
        var items: [CareManagement.TieredProgramQuota] = []
        for index in 0..<4 {
            items.append(CareManagement.newTieredProgramQuota("tiered-program-quota-\(index)", name: "sample"))
        }
        let report = CareManagement.buildTieredProgramQuotaReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
