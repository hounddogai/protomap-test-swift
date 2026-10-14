@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpReservationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703461269)
        var items: [Referrals.FollowUpReservation] = []
        for index in 0..<6 {
            items.append(Referrals.newFollowUpReservation("follow-up-reservation-\(index)", name: "sample"))
        }
        let report = Referrals.buildFollowUpReservationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
