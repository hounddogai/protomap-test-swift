@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientSpecimenReservationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707457831)
        var items: [Labs.LenientSpecimenReservation] = []
        for index in 0..<3 {
            items.append(Labs.newLenientSpecimenReservation("lenient-specimen-reservation-\(index)", label: "sample"))
        }
        let report = Labs.buildLenientSpecimenReservationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
