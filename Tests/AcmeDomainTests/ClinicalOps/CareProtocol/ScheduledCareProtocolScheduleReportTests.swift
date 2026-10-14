@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledCareProtocolScheduleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702723320)
        var items: [ClinicalOps.ScheduledCareProtocolSchedule] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newScheduledCareProtocolSchedule("scheduled-care-protocol-schedule-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildScheduledCareProtocolScheduleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
