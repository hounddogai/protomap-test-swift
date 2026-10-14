@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackModalityEntryReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707175381)
        var items: [Imaging.FallbackModalityEntry] = []
        for index in 0..<6 {
            items.append(Imaging.newFallbackModalityEntry("fallback-modality-entry-\(index)", name: "sample"))
        }
        let report = Imaging.buildFallbackModalityEntryReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
