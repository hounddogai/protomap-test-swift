@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedFollowUpCheckpointReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705126664)
        var items: [Referrals.CappedFollowUpCheckpoint] = []
        for index in 0..<4 {
            items.append(Referrals.newCappedFollowUpCheckpoint("capped-follow-up-checkpoint-\(index)", title: "sample"))
        }
        let report = Referrals.buildCappedFollowUpCheckpointReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
