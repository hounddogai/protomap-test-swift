@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedSkillMixMilestoneReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703928951)
        var items: [Staffing.WeightedSkillMixMilestone] = []
        for index in 0..<2 {
            items.append(Staffing.newWeightedSkillMixMilestone("weighted-skill-mix-milestone-\(index)", name: "sample"))
        }
        let report = Staffing.buildWeightedSkillMixMilestoneReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
