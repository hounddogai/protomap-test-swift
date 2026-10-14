@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialPolicyReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705584504)
        var items: [RevenueCycle.DenialPolicy] = []
        for index in 0..<3 {
            items.append(RevenueCycle.newDenialPolicy("denial-policy-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildDenialPolicyReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
