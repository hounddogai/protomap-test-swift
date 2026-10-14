@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationAllocationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700246127)
        var items: [RevenueCycle.AuthorizationAllocation] = []
        for index in 0..<5 {
            items.append(RevenueCycle.newAuthorizationAllocation("authorization-allocation-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildAuthorizationAllocationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
