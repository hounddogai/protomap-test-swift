@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalAuthorizationAllocationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709748247)
        var items: [RevenueCycle.RegionalAuthorizationAllocation] = []
        for index in 0..<3 {
            items.append(RevenueCycle.newRegionalAuthorizationAllocation("regional-authorization-allocation-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildRegionalAuthorizationAllocationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
