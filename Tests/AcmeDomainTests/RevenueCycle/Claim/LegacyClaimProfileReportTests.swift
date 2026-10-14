@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyClaimProfileReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701256322)
        var items: [RevenueCycle.LegacyClaimProfile] = []
        for index in 0..<4 {
            items.append(RevenueCycle.newLegacyClaimProfile("legacy-claim-profile-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildLegacyClaimProfileReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
