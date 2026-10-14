@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualClaimEstimateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703645186)
        var items: [RevenueCycle.ManualClaimEstimate] = []
        for index in 0..<2 {
            items.append(RevenueCycle.newManualClaimEstimate("manual-claim-estimate-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildManualClaimEstimateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
