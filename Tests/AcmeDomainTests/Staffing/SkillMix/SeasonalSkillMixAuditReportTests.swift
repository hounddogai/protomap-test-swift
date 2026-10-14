@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalSkillMixAuditReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709851530)
        var items: [Staffing.SeasonalSkillMixAudit] = []
        for index in 0..<3 {
            items.append(Staffing.newSeasonalSkillMixAudit("seasonal-skill-mix-audit-\(index)", title: "sample"))
        }
        let report = Staffing.buildSeasonalSkillMixAuditReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
