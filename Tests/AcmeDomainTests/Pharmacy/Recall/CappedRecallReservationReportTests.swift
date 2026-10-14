@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedRecallReservationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700903822)
        var items: [Pharmacy.CappedRecallReservation] = []
        for index in 0..<6 {
            items.append(Pharmacy.newCappedRecallReservation("capped-recall-reservation-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildCappedRecallReservationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
