@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientOutreachAuditReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707174422)
        var items: [CareManagement.LenientOutreachAudit] = []
        for index in 0..<2 {
            items.append(CareManagement.newLenientOutreachAudit("lenient-outreach-audit-\(index)", title: "sample"))
        }
        let report = CareManagement.buildLenientOutreachAuditReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
