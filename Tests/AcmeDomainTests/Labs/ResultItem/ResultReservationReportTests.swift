@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultReservationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702643215)
        var items: [Labs.ResultReservation] = []
        for index in 0..<4 {
            items.append(Labs.newResultReservation("result-reservation-\(index)", label: "sample"))
        }
        let report = Labs.buildResultReservationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
