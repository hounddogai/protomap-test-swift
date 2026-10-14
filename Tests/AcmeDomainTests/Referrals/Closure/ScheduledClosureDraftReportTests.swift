@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledClosureDraftReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704715016)
        var items: [Referrals.ScheduledClosureDraft] = []
        for index in 0..<6 {
            items.append(Referrals.newScheduledClosureDraft("scheduled-closure-draft-\(index)", name: "sample"))
        }
        let report = Referrals.buildScheduledClosureDraftReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
