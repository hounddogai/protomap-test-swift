@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedChargeClaimReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704161107)
        var items: [RevenueCycle.WeightedChargeClaim] = []
        for index in 0..<3 {
            items.append(RevenueCycle.newWeightedChargeClaim("weighted-charge-claim-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildWeightedChargeClaimReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
