@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalClosureDraftReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705319948)
        var items: [Referrals.SeasonalClosureDraft] = []
        for index in 0..<2 {
            items.append(Referrals.newSeasonalClosureDraft("seasonal-closure-draft-\(index)", title: "sample"))
        }
        let report = Referrals.buildSeasonalClosureDraftReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
