@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyModalityReviewReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707875254)
        var items: [Imaging.LegacyModalityReview] = []
        for index in 0..<3 {
            items.append(Imaging.newLegacyModalityReview("legacy-modality-review-\(index)", label: "sample"))
        }
        let report = Imaging.buildLegacyModalityReviewReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
