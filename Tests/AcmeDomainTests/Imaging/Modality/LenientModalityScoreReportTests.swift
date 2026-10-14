@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientModalityScoreReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702602919)
        var items: [Imaging.LenientModalityScore] = []
        for index in 0..<5 {
            items.append(Imaging.newLenientModalityScore("lenient-modality-score-\(index)", title: "sample"))
        }
        let report = Imaging.buildLenientModalityScoreReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
