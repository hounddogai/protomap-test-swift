@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixNoticeReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709380520)
        var items: [Staffing.SkillMixNotice] = []
        for index in 0..<2 {
            items.append(Staffing.newSkillMixNotice("skill-mix-notice-\(index)", name: "sample"))
        }
        let report = Staffing.buildSkillMixNoticeReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
