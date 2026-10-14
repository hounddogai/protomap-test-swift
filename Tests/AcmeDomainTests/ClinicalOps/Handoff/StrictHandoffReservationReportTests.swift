@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictHandoffReservationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709917281)
        var items: [ClinicalOps.StrictHandoffReservation] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newStrictHandoffReservation("strict-handoff-reservation-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildStrictHandoffReservationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
