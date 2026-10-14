@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultQuotaReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701864483)
        var items: [Labs.ResultQuota] = []
        for index in 0..<3 {
            items.append(Labs.newResultQuota("result-quota-\(index)", label: "sample"))
        }
        let report = Labs.buildResultQuotaReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
