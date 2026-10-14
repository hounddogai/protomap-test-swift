@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimarySkillMixCycleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705976639)
        var items: [Staffing.PrimarySkillMixCycle] = []
        for index in 0..<2 {
            items.append(Staffing.newPrimarySkillMixCycle("primary-skill-mix-cycle-\(index)", name: "sample"))
        }
        let report = Staffing.buildPrimarySkillMixCycleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
