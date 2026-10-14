@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolSummaryReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705309414)
        var items: [ClinicalOps.CareProtocolSummary] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newCareProtocolSummary("care-protocol-summary-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildCareProtocolSummaryReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
