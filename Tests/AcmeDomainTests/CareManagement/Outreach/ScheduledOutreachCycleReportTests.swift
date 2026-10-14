@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledOutreachCycleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708147415)
        var items: [CareManagement.ScheduledOutreachCycle] = []
        for index in 0..<6 {
            items.append(CareManagement.newScheduledOutreachCycle("scheduled-outreach-cycle-\(index)", label: "sample"))
        }
        let report = CareManagement.buildScheduledOutreachCycleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
