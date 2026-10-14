@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveCleaningMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703356668)
        var items: [BedManagement.AdaptiveCleaningMetric] = []
        for index in 0..<6 {
            items.append(BedManagement.newAdaptiveCleaningMetric("adaptive-cleaning-metric-\(index)", name: "sample"))
        }
        let report = BedManagement.buildAdaptiveCleaningMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
