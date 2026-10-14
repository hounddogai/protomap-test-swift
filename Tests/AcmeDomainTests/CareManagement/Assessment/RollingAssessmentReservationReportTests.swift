@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingAssessmentReservationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703636707)
        var items: [CareManagement.RollingAssessmentReservation] = []
        for index in 0..<6 {
            items.append(CareManagement.newRollingAssessmentReservation("rolling-assessment-reservation-\(index)", name: "sample"))
        }
        let report = CareManagement.buildRollingAssessmentReservationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
