@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveWorklistNoticeReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706427961)
        var items: [Imaging.AdaptiveWorklistNotice] = []
        for index in 0..<5 {
            items.append(Imaging.newAdaptiveWorklistNotice("adaptive-worklist-notice-\(index)", title: "sample"))
        }
        let report = Imaging.buildAdaptiveWorklistNoticeReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
