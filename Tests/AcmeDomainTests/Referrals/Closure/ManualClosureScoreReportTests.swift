@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualClosureScoreReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701287530)
        var items: [Referrals.ManualClosureScore] = []
        for index in 0..<2 {
            items.append(Referrals.newManualClosureScore("manual-closure-score-\(index)", label: "sample"))
        }
        let report = Referrals.buildManualClosureScoreReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
