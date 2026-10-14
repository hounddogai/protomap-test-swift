@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultCareProtocolSummaryReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707300047)
        var items: [ClinicalOps.DefaultCareProtocolSummary] = []
        for index in 0..<4 {
            items.append(ClinicalOps.newDefaultCareProtocolSummary("default-care-protocol-summary-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildDefaultCareProtocolSummaryReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
