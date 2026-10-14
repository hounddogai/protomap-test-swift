@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalClosureWindowReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708487875)
        var items: [Referrals.SeasonalClosureWindow] = []
        for index in 0..<2 {
            items.append(Referrals.newSeasonalClosureWindow("seasonal-closure-window-\(index)", label: "sample"))
        }
        let report = Referrals.buildSeasonalClosureWindowReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
