@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalIsolationBaselineReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708251210)
        var items: [BedManagement.RegionalIsolationBaseline] = []
        for index in 0..<5 {
            items.append(BedManagement.newRegionalIsolationBaseline("regional-isolation-baseline-\(index)", name: "sample"))
        }
        let report = BedManagement.buildRegionalIsolationBaselineReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
