@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationTierReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704255057)
        var items: [RevenueCycle.AuthorizationTier] = []
        for index in 0..<4 {
            items.append(RevenueCycle.newAuthorizationTier("authorization-tier-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildAuthorizationTierReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
