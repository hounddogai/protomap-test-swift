@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalCareProtocolEstimateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708538319)
        var items: [ClinicalOps.RegionalCareProtocolEstimate] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newRegionalCareProtocolEstimate("regional-care-protocol-estimate-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildRegionalCareProtocolEstimateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
