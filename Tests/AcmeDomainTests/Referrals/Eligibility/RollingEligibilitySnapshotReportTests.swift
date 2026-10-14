@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingEligibilitySnapshotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709294156)
        var items: [Referrals.RollingEligibilitySnapshot] = []
        for index in 0..<2 {
            items.append(Referrals.newRollingEligibilitySnapshot("rolling-eligibility-snapshot-\(index)", name: "sample"))
        }
        let report = Referrals.buildRollingEligibilitySnapshotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
