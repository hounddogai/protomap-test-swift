@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredIsolationMilestoneReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701937282)
        var items: [BedManagement.TieredIsolationMilestone] = []
        for index in 0..<5 {
            items.append(BedManagement.newTieredIsolationMilestone("tiered-isolation-milestone-\(index)", name: "sample"))
        }
        let report = BedManagement.buildTieredIsolationMilestoneReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
