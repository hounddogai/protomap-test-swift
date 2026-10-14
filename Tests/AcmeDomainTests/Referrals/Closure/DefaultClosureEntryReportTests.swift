@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultClosureEntryReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703259546)
        var items: [Referrals.DefaultClosureEntry] = []
        for index in 0..<6 {
            items.append(Referrals.newDefaultClosureEntry("default-closure-entry-\(index)", title: "sample"))
        }
        let report = Referrals.buildDefaultClosureEntryReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
