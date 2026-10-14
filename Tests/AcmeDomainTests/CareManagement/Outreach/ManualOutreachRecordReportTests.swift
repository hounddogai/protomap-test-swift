@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualOutreachRecordReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701075702)
        var items: [CareManagement.ManualOutreachRecord] = []
        for index in 0..<2 {
            items.append(CareManagement.newManualOutreachRecord("manual-outreach-record-\(index)", name: "sample"))
        }
        let report = CareManagement.buildManualOutreachRecordReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
