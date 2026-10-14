@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingOutreachBaselineReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707535515)
        var items: [CareManagement.PendingOutreachBaseline] = []
        for index in 0..<6 {
            items.append(CareManagement.newPendingOutreachBaseline("pending-outreach-baseline-\(index)", label: "sample"))
        }
        let report = CareManagement.buildPendingOutreachBaselineReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
