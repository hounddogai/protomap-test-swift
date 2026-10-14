@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedFollowUpAssignmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700242928)
        var items: [Referrals.WeightedFollowUpAssignment] = []
        for index in 0..<5 {
            items.append(Referrals.newWeightedFollowUpAssignment("weighted-follow-up-assignment-\(index)", label: "sample"))
        }
        let report = Referrals.buildWeightedFollowUpAssignmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
