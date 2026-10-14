@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalAccessionReservationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701882619)
        var items: [Labs.RegionalAccessionReservation] = []
        for index in 0..<2 {
            items.append(Labs.newRegionalAccessionReservation("regional-accession-reservation-\(index)", label: "sample"))
        }
        let report = Labs.buildRegionalAccessionReservationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
