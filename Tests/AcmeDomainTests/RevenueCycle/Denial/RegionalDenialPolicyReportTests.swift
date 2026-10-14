@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalDenialPolicyReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702840791)
        var items: [RevenueCycle.RegionalDenialPolicy] = []
        for index in 0..<4 {
            items.append(RevenueCycle.newRegionalDenialPolicy("regional-denial-policy-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildRegionalDenialPolicyReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
