@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryResultSummaryReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701619792)
        var items: [Labs.PrimaryResultSummary] = []
        for index in 0..<3 {
            items.append(Labs.newPrimaryResultSummary("primary-result-summary-\(index)", name: "sample"))
        }
        let report = Labs.buildPrimaryResultSummaryReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
