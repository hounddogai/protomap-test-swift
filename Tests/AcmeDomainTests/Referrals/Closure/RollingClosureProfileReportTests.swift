@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingClosureProfileReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706216567)
        var items: [Referrals.RollingClosureProfile] = []
        for index in 0..<2 {
            items.append(Referrals.newRollingClosureProfile("rolling-closure-profile-\(index)", title: "sample"))
        }
        let report = Referrals.buildRollingClosureProfileReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
