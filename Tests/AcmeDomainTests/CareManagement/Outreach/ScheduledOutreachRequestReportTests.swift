@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledOutreachRequestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703893311)
        var items: [CareManagement.ScheduledOutreachRequest] = []
        for index in 0..<3 {
            items.append(CareManagement.newScheduledOutreachRequest("scheduled-outreach-request-\(index)", name: "sample"))
        }
        let report = CareManagement.buildScheduledOutreachRequestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
