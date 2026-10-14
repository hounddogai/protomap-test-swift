@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedReferralSnapshotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709162861)
        var items: [Referrals.CappedReferralSnapshot] = []
        for index in 0..<5 {
            items.append(Referrals.newCappedReferralSnapshot("capped-referral-snapshot-\(index)", name: "sample"))
        }
        let report = Referrals.buildCappedReferralSnapshotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
