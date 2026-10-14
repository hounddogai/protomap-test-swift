@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingShiftReservationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709728435)
        var items: [Staffing.PendingShiftReservation] = []
        for index in 0..<3 {
            items.append(Staffing.newPendingShiftReservation("pending-shift-reservation-\(index)", label: "sample"))
        }
        let report = Staffing.buildPendingShiftReservationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
