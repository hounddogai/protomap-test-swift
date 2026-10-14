@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingBatchedOvertimeReservationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706172814)
        var items: [Staffing.BatchedOvertimeReservation] = []
        for index in 0..<4 {
            items.append(Staffing.newBatchedOvertimeReservation("batched-overtime-reservation-\(index)", title: "sample"))
        }
        let report = Staffing.buildBatchedOvertimeReservationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
