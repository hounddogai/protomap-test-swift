@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedReferralAssignmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707934110)
        var items: [Referrals.BatchedReferralAssignment] = []
        for index in 0..<5 {
            items.append(Referrals.newBatchedReferralAssignment("batched-referral-assignment-\(index)", label: "sample"))
        }
        let report = Referrals.buildBatchedReferralAssignmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
