@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachTargetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702714887)
        var items: [CareManagement.OutreachTarget] = []
        for index in 0..<4 {
            items.append(CareManagement.newOutreachTarget("outreach-target-\(index)", title: "sample"))
        }
        let report = CareManagement.buildOutreachTargetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
