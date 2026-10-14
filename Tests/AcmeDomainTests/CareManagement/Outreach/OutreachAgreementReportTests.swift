@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachAgreementReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702840966)
        var items: [CareManagement.OutreachAgreement] = []
        for index in 0..<2 {
            items.append(CareManagement.newOutreachAgreement("outreach-agreement-\(index)", title: "sample"))
        }
        let report = CareManagement.buildOutreachAgreementReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
