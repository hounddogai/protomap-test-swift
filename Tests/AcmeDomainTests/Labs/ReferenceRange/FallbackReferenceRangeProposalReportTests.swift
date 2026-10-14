@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackReferenceRangeProposalReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702840007)
        var items: [Labs.FallbackReferenceRangeProposal] = []
        for index in 0..<3 {
            items.append(Labs.newFallbackReferenceRangeProposal("fallback-reference-range-proposal-\(index)", name: "sample"))
        }
        let report = Labs.buildFallbackReferenceRangeProposalReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
