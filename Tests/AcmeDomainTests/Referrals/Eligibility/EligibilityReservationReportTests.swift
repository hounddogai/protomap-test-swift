@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityReservationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700752684)
        var items: [Referrals.EligibilityReservation] = []
        for index in 0..<5 {
            items.append(Referrals.newEligibilityReservation("eligibility-reservation-\(index)", name: "sample"))
        }
        let report = Referrals.buildEligibilityReservationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
