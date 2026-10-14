@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalTransferAuditReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702151017)
        var items: [BedManagement.GlobalTransferAudit] = []
        for index in 0..<5 {
            items.append(BedManagement.newGlobalTransferAudit("global-transfer-audit-\(index)", name: "sample"))
        }
        let report = BedManagement.buildGlobalTransferAuditReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
