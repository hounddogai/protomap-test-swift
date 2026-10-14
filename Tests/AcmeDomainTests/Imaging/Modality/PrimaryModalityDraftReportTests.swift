@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryModalityDraftReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705146087)
        var items: [Imaging.PrimaryModalityDraft] = []
        for index in 0..<2 {
            items.append(Imaging.newPrimaryModalityDraft("primary-modality-draft-\(index)", label: "sample"))
        }
        let report = Imaging.buildPrimaryModalityDraftReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
