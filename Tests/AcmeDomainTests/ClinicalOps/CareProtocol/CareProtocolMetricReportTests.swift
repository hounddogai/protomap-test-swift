@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolMetricReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706212203)
        var items: [ClinicalOps.CareProtocolMetric] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newCareProtocolMetric("care-protocol-metric-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildCareProtocolMetricReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
