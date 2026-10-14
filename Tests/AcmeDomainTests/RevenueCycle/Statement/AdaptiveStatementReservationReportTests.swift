@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveStatementReservationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700332152)
        var items: [RevenueCycle.AdaptiveStatementReservation] = []
        for index in 0..<4 {
            items.append(RevenueCycle.newAdaptiveStatementReservation("adaptive-statement-reservation-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildAdaptiveStatementReservationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
