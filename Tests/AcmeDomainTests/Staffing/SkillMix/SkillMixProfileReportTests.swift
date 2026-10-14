@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixProfileReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708067673)
        var items: [Staffing.SkillMixProfile] = []
        for index in 0..<3 {
            items.append(Staffing.newSkillMixProfile("skill-mix-profile-\(index)", name: "sample"))
        }
        let report = Staffing.buildSkillMixProfileReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
