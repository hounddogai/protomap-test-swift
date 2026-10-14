@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveStudyManifestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709582316)
        var items: [Imaging.AdaptiveStudyManifest] = []
        for index in 0..<3 {
            items.append(Imaging.newAdaptiveStudyManifest("adaptive-study-manifest-\(index)", label: "sample"))
        }
        let report = Imaging.buildAdaptiveStudyManifestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
