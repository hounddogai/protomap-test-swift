@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityProposalReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701928533)
        var items: [Imaging.ModalityProposal] = []
        for index in 0..<2 {
            items.append(Imaging.newModalityProposal("modality-proposal-\(index)", name: "sample"))
        }
        let report = Imaging.buildModalityProposalReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
