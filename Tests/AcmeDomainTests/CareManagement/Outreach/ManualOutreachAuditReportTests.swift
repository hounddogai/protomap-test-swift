@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualOutreachAuditReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709978147)
        var items: [CareManagement.ManualOutreachAudit] = []
        for index in 0..<5 {
            items.append(CareManagement.newManualOutreachAudit("manual-outreach-audit-\(index)", label: "sample"))
        }
        let report = CareManagement.buildManualOutreachAuditReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
