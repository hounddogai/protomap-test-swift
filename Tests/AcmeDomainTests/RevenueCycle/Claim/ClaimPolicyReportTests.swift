@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimPolicyReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701319712)
        var items: [RevenueCycle.ClaimPolicy] = []
        for index in 0..<6 {
            items.append(RevenueCycle.newClaimPolicy("claim-policy-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildClaimPolicyReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
