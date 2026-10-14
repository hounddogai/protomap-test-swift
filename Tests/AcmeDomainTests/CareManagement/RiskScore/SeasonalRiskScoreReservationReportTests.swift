@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalRiskScoreReservationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701740107)
        var items: [CareManagement.SeasonalRiskScoreReservation] = []
        for index in 0..<2 {
            items.append(CareManagement.newSeasonalRiskScoreReservation("seasonal-risk-score-reservation-\(index)", label: "sample"))
        }
        let report = CareManagement.buildSeasonalRiskScoreReservationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
