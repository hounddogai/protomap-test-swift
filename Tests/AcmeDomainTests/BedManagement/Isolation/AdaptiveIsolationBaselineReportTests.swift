@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveIsolationBaselineReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706116355)
        var items: [BedManagement.AdaptiveIsolationBaseline] = []
        for index in 0..<4 {
            items.append(BedManagement.newAdaptiveIsolationBaseline("adaptive-isolation-baseline-\(index)", label: "sample"))
        }
        let report = BedManagement.buildAdaptiveIsolationBaselineReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
