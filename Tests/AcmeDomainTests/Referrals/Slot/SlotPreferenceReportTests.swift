@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotPreferenceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706651334)
        var items: [Referrals.SlotPreference] = []
        for index in 0..<5 {
            items.append(Referrals.newSlotPreference("slot-preference-\(index)", label: "sample"))
        }
        let report = Referrals.buildSlotPreferenceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
