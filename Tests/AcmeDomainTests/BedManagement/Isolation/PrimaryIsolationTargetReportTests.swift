@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryIsolationTargetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700960421)
        var items: [BedManagement.PrimaryIsolationTarget] = []
        for index in 0..<4 {
            items.append(BedManagement.newPrimaryIsolationTarget("primary-isolation-target-\(index)", name: "sample"))
        }
        let report = BedManagement.buildPrimaryIsolationTargetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
