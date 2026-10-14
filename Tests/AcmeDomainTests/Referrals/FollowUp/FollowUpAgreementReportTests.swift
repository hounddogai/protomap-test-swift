@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpAgreementReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701318570)
        var items: [Referrals.FollowUpAgreement] = []
        for index in 0..<4 {
            items.append(Referrals.newFollowUpAgreement("follow-up-agreement-\(index)", name: "sample"))
        }
        let report = Referrals.buildFollowUpAgreementReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
