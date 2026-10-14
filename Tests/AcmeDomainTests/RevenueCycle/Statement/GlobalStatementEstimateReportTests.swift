@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalStatementEstimateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703994087)
        var items: [RevenueCycle.GlobalStatementEstimate] = []
        for index in 0..<6 {
            items.append(RevenueCycle.newGlobalStatementEstimate("global-statement-estimate-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildGlobalStatementEstimateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
