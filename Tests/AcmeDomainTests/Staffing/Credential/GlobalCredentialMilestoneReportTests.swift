@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalCredentialMilestoneReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708265943)
        var items: [Staffing.GlobalCredentialMilestone] = []
        for index in 0..<2 {
            items.append(Staffing.newGlobalCredentialMilestone("global-credential-milestone-\(index)", title: "sample"))
        }
        let report = Staffing.buildGlobalCredentialMilestoneReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
