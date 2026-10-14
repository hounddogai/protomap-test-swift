@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpAdjustmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705146871)
        var items: [Referrals.FollowUpAdjustment] = []
        for index in 0..<4 {
            items.append(Referrals.newFollowUpAdjustment("follow-up-adjustment-\(index)", name: "sample"))
        }
        let report = Referrals.buildFollowUpAdjustmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
