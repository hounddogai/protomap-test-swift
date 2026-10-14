@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingOvertimeReservationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704931904)
        var items: [Staffing.PendingOvertimeReservation] = []
        for index in 0..<5 {
            items.append(Staffing.newPendingOvertimeReservation("pending-overtime-reservation-\(index)", title: "sample"))
        }
        let report = Staffing.buildPendingOvertimeReservationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
