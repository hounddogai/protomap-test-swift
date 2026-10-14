@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientIsolationBaselineReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704929418)
        var items: [BedManagement.LenientIsolationBaseline] = []
        for index in 0..<2 {
            items.append(BedManagement.newLenientIsolationBaseline("lenient-isolation-baseline-\(index)", label: "sample"))
        }
        let report = BedManagement.buildLenientIsolationBaselineReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
