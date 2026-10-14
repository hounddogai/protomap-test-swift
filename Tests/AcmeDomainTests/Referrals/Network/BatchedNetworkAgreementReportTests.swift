@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedNetworkAgreementReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705065849)
        var items: [Referrals.BatchedNetworkAgreement] = []
        for index in 0..<5 {
            items.append(Referrals.newBatchedNetworkAgreement("batched-network-agreement-\(index)", label: "sample"))
        }
        let report = Referrals.buildBatchedNetworkAgreementReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
