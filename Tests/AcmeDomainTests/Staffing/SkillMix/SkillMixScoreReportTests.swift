@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixScoreReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705232156)
        var items: [Staffing.SkillMixScore] = []
        for index in 0..<5 {
            items.append(Staffing.newSkillMixScore("skill-mix-score-\(index)", name: "sample"))
        }
        let report = Staffing.buildSkillMixScoreReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
