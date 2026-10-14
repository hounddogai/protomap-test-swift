@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultHandoffReservationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701934350)
        var items: [ClinicalOps.DefaultHandoffReservation] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newDefaultHandoffReservation("default-handoff-reservation-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildDefaultHandoffReservationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
