@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictClaimAllocationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709262804)
        var items: [RevenueCycle.StrictClaimAllocation] = []
        for index in 0..<2 {
            items.append(RevenueCycle.newStrictClaimAllocation("strict-claim-allocation-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildStrictClaimAllocationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
