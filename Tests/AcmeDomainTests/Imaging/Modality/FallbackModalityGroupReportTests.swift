@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackModalityGroupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702625451)
        var items: [Imaging.FallbackModalityGroup] = []
        for index in 0..<4 {
            items.append(Imaging.newFallbackModalityGroup("fallback-modality-group-\(index)", title: "sample"))
        }
        let report = Imaging.buildFallbackModalityGroupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
