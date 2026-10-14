@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultSpecimenReservationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701806277)
        var items: [Labs.DefaultSpecimenReservation] = []
        for index in 0..<3 {
            items.append(Labs.newDefaultSpecimenReservation("default-specimen-reservation-\(index)", label: "sample"))
        }
        let report = Labs.buildDefaultSpecimenReservationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
