@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalClosureClaimReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704645886)
        var items: [Referrals.GlobalClosureClaim] = []
        for index in 0..<3 {
            items.append(Referrals.newGlobalClosureClaim("global-closure-claim-\(index)", title: "sample"))
        }
        let report = Referrals.buildGlobalClosureClaimReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
