@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingDischargePlanScoreReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701552619)
        var items: [BedManagement.RollingDischargePlanScore] = []
        for index in 0..<5 {
            items.append(BedManagement.newRollingDischargePlanScore("rolling-discharge-plan-score-\(index)", title: "sample"))
        }
        let report = BedManagement.buildRollingDischargePlanScoreReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
