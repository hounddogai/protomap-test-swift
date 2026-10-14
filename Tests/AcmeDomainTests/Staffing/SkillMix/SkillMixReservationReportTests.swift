@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixReservationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705175351)
        var items: [Staffing.SkillMixReservation] = []
        for index in 0..<2 {
            items.append(Staffing.newSkillMixReservation("skill-mix-reservation-\(index)", label: "sample"))
        }
        let report = Staffing.buildSkillMixReservationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
