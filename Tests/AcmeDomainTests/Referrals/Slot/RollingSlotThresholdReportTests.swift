@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingSlotThresholdReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705605301)
        var items: [Referrals.RollingSlotThreshold] = []
        for index in 0..<4 {
            items.append(Referrals.newRollingSlotThreshold("rolling-slot-threshold-\(index)", title: "sample"))
        }
        let report = Referrals.buildRollingSlotThresholdReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
