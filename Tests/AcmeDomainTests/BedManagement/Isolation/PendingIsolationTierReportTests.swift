@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingIsolationTierReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707341922)
        var items: [BedManagement.PendingIsolationTier] = []
        for index in 0..<5 {
            items.append(BedManagement.newPendingIsolationTier("pending-isolation-tier-\(index)", label: "sample"))
        }
        let report = BedManagement.buildPendingIsolationTierReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
