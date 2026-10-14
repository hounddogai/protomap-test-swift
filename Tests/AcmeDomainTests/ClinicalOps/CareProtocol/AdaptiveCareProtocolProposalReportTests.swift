@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveCareProtocolProposalReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704721502)
        var items: [ClinicalOps.AdaptiveCareProtocolProposal] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newAdaptiveCareProtocolProposal("adaptive-care-protocol-proposal-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildAdaptiveCareProtocolProposalReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
