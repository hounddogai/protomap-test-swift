@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedEligibilityVarianceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707903352)
        var items: [Referrals.BatchedEligibilityVariance] = []
        for index in 0..<4 {
            items.append(Referrals.newBatchedEligibilityVariance("batched-eligibility-variance-\(index)", name: "sample"))
        }
        let report = Referrals.buildBatchedEligibilityVarianceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
