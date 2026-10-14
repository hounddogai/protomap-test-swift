@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientAuthorizationDigestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700742532)
        var items: [RevenueCycle.LenientAuthorizationDigest] = []
        for index in 0..<3 {
            items.append(RevenueCycle.newLenientAuthorizationDigest("lenient-authorization-digest-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildLenientAuthorizationDigestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
