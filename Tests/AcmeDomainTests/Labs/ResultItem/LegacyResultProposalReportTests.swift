@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyResultProposalReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701048309)
        var items: [Labs.LegacyResultProposal] = []
        for index in 0..<6 {
            items.append(Labs.newLegacyResultProposal("legacy-result-proposal-\(index)", title: "sample"))
        }
        let report = Labs.buildLegacyResultProposalReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
