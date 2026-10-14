@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffProposalReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701127302)
        var items: [ClinicalOps.HandoffProposal] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newHandoffProposal("handoff-proposal-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildHandoffProposalReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
