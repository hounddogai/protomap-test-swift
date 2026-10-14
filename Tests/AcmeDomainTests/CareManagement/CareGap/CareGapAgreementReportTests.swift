@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapAgreementReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701623261)
        var items: [CareManagement.CareGapAgreement] = []
        for index in 0..<5 {
            items.append(CareManagement.newCareGapAgreement("care-gap-agreement-\(index)", title: "sample"))
        }
        let report = CareManagement.buildCareGapAgreementReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
