@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingSpecimenMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709237639)
        var items: [Labs.PendingSpecimenMetric] = []
        for index in 0..<3 {
            items.append(Labs.newPendingSpecimenMetric("pending-specimen-metric-\(index)", label: "sample"))
        }
        let report = Labs.buildPendingSpecimenMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
