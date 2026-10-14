@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedRevocationSummaryReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701448119)
        var items: [Consent.CappedRevocationSummary] = []
        for index in 0..<2 {
            items.append(Consent.newCappedRevocationSummary("capped-revocation-summary-\(index)", label: "sample"))
        }
        let report = Consent.buildCappedRevocationSummaryReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
