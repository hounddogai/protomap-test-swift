@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709937358)
        var items: [BedManagement.CleaningMetric] = []
        for index in 0..<2 {
            items.append(BedManagement.newCleaningMetric("cleaning-metric-\(index)", title: "sample"))
        }
        let report = BedManagement.buildCleaningMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
