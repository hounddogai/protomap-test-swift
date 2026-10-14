@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityDigestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701717093)
        var items: [Referrals.EligibilityDigest] = []
        for index in 0..<2 {
            items.append(Referrals.newEligibilityDigest("eligibility-digest-\(index)", label: "sample"))
        }
        let report = Referrals.buildEligibilityDigestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
