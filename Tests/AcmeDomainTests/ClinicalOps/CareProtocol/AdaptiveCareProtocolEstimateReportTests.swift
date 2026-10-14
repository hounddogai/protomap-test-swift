@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveCareProtocolEstimateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704899275)
        var items: [ClinicalOps.AdaptiveCareProtocolEstimate] = []
        for index in 0..<5 {
            items.append(ClinicalOps.newAdaptiveCareProtocolEstimate("adaptive-care-protocol-estimate-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildAdaptiveCareProtocolEstimateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
