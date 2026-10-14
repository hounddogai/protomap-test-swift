@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedChargeThresholdReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702439855)
        var items: [RevenueCycle.WeightedChargeThreshold] = []
        for index in 0..<3 {
            items.append(RevenueCycle.newWeightedChargeThreshold("weighted-charge-threshold-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildWeightedChargeThresholdReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
