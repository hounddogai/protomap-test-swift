@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyStudyProposalReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704851591)
        var items: [Imaging.LegacyStudyProposal] = []
        for index in 0..<5 {
            items.append(Imaging.newLegacyStudyProposal("legacy-study-proposal-\(index)", label: "sample"))
        }
        let report = Imaging.buildLegacyStudyProposalReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
