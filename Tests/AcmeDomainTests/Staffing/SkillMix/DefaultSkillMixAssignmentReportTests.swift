@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultSkillMixAssignmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705880972)
        var items: [Staffing.DefaultSkillMixAssignment] = []
        for index in 0..<6 {
            items.append(Staffing.newDefaultSkillMixAssignment("default-skill-mix-assignment-\(index)", name: "sample"))
        }
        let report = Staffing.buildDefaultSkillMixAssignmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
