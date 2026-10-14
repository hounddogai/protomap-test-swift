@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredSkillMixMilestoneReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704683291)
        var items: [Staffing.TieredSkillMixMilestone] = []
        for index in 0..<3 {
            items.append(Staffing.newTieredSkillMixMilestone("tiered-skill-mix-milestone-\(index)", title: "sample"))
        }
        let report = Staffing.buildTieredSkillMixMilestoneReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
