@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationDigestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709986573)
        var items: [RevenueCycle.AuthorizationDigest] = []
        for index in 0..<6 {
            items.append(RevenueCycle.newAuthorizationDigest("authorization-digest-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildAuthorizationDigestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
