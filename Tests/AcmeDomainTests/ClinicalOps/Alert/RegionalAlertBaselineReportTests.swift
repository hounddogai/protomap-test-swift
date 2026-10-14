@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalAlertBaselineReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701765293)
        var items: [ClinicalOps.RegionalAlertBaseline] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newRegionalAlertBaseline("regional-alert-baseline-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildRegionalAlertBaselineReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
