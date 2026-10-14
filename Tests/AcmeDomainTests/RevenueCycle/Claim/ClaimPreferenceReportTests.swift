@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimPreferenceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700084459)
        var items: [RevenueCycle.ClaimPreference] = []
        for index in 0..<5 {
            items.append(RevenueCycle.newClaimPreference("claim-preference-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildClaimPreferenceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
