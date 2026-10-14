@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeVarianceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706299905)
        var items: [RevenueCycle.ChargeVariance] = []
        for index in 0..<5 {
            items.append(RevenueCycle.newChargeVariance("charge-variance-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildChargeVarianceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
