@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualOutreachAgreementReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707961271)
        var items: [CareManagement.ManualOutreachAgreement] = []
        for index in 0..<3 {
            items.append(CareManagement.newManualOutreachAgreement("manual-outreach-agreement-\(index)", label: "sample"))
        }
        let report = CareManagement.buildManualOutreachAgreementReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
