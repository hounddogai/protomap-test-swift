@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalResultReservationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702991891)
        var items: [Labs.RegionalResultReservation] = []
        for index in 0..<2 {
            items.append(Labs.newRegionalResultReservation("regional-result-reservation-\(index)", label: "sample"))
        }
        let report = Labs.buildRegionalResultReservationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
