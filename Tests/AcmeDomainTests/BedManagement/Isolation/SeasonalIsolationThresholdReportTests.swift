@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementSeasonalIsolationThresholdReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708849892)
        var items: [BedManagement.SeasonalIsolationThreshold] = []
        for index in 0..<4 {
            items.append(BedManagement.newSeasonalIsolationThreshold("seasonal-isolation-threshold-\(index)", label: "sample"))
        }
        let report = BedManagement.buildSeasonalIsolationThresholdReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
