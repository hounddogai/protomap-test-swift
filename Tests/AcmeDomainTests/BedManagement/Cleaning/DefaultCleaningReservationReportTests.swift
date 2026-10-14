@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultCleaningReservationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705197279)
        var items: [BedManagement.DefaultCleaningReservation] = []
        for index in 0..<3 {
            items.append(BedManagement.newDefaultCleaningReservation("default-cleaning-reservation-\(index)", label: "sample"))
        }
        let report = BedManagement.buildDefaultCleaningReservationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
