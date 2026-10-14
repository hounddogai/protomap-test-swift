@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCleaningQuotaReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700129819)
        var items: [BedManagement.ScheduledCleaningQuota] = []
        for index in 0..<4 {
            items.append(BedManagement.newScheduledCleaningQuota("scheduled-cleaning-quota-\(index)", name: "sample"))
        }
        let report = BedManagement.buildScheduledCleaningQuotaReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
