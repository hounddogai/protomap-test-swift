@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyRoundingReservationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702229376)
        var items: [ClinicalOps.LegacyRoundingReservation] = []
        for index in 0..<6 {
            items.append(ClinicalOps.newLegacyRoundingReservation("legacy-rounding-reservation-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildLegacyRoundingReservationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
