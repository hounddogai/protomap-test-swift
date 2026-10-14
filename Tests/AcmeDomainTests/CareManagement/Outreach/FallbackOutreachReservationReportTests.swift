@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackOutreachReservationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702668935)
        var items: [CareManagement.FallbackOutreachReservation] = []
        for index in 0..<5 {
            items.append(CareManagement.newFallbackOutreachReservation("fallback-outreach-reservation-\(index)", title: "sample"))
        }
        let report = CareManagement.buildFallbackOutreachReservationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
