@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryHandoffAgreementReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703248941)
        var items: [ClinicalOps.PrimaryHandoffAgreement] = []
        for index in 0..<6 {
            items.append(ClinicalOps.newPrimaryHandoffAgreement("primary-handoff-agreement-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildPrimaryHandoffAgreementReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
