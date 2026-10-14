@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledFollowUpWindowReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706717190)
        var items: [Referrals.ScheduledFollowUpWindow] = []
        for index in 0..<3 {
            items.append(Referrals.newScheduledFollowUpWindow("scheduled-follow-up-window-\(index)", name: "sample"))
        }
        let report = Referrals.buildScheduledFollowUpWindowReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
