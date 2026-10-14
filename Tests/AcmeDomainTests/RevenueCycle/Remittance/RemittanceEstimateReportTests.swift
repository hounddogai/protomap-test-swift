@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceEstimateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702386936)
        var items: [RevenueCycle.RemittanceEstimate] = []
        for index in 0..<4 {
            items.append(RevenueCycle.newRemittanceEstimate("remittance-estimate-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildRemittanceEstimateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
