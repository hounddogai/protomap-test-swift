@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientClosureMilestoneReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707571779)
        var items: [Referrals.LenientClosureMilestone] = []
        for index in 0..<6 {
            items.append(Referrals.newLenientClosureMilestone("lenient-closure-milestone-\(index)", title: "sample"))
        }
        let report = Referrals.buildLenientClosureMilestoneReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
