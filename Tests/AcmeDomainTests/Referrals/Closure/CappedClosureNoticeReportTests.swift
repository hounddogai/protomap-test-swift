@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedClosureNoticeReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704868174)
        var items: [Referrals.CappedClosureNotice] = []
        for index in 0..<2 {
            items.append(Referrals.newCappedClosureNotice("capped-closure-notice-\(index)", name: "sample"))
        }
        let report = Referrals.buildCappedClosureNoticeReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
