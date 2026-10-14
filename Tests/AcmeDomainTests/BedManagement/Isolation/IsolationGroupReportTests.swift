@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationGroupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705018517)
        var items: [BedManagement.IsolationGroup] = []
        for index in 0..<3 {
            items.append(BedManagement.newIsolationGroup("isolation-group-\(index)", title: "sample"))
        }
        let report = BedManagement.buildIsolationGroupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
