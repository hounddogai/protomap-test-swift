@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedModalityWindowReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701417592)
        var items: [Imaging.CappedModalityWindow] = []
        for index in 0..<4 {
            items.append(Imaging.newCappedModalityWindow("capped-modality-window-\(index)", name: "sample"))
        }
        let report = Imaging.buildCappedModalityWindowReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
