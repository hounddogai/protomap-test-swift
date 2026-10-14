@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationPolicyReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703296328)
        var items: [RevenueCycle.AuthorizationPolicy] = []
        for index in 0..<5 {
            items.append(RevenueCycle.newAuthorizationPolicy("authorization-policy-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildAuthorizationPolicyReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
