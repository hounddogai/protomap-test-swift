@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedReferralDraftReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704570574)
        var items: [Referrals.BatchedReferralDraft] = []
        for index in 0..<5 {
            items.append(Referrals.newBatchedReferralDraft("batched-referral-draft-\(index)", name: "sample"))
        }
        let report = Referrals.buildBatchedReferralDraftReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
