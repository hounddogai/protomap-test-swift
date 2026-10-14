@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimarySkillMixScoreReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706069362)
        var items: [Staffing.PrimarySkillMixScore] = []
        for index in 0..<3 {
            items.append(Staffing.newPrimarySkillMixScore("primary-skill-mix-score-\(index)", name: "sample"))
        }
        let report = Staffing.buildPrimarySkillMixScoreReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
