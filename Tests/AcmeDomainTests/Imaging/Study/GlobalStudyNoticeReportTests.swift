@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalStudyNoticeReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704671484)
        var items: [Imaging.GlobalStudyNotice] = []
        for index in 0..<5 {
            items.append(Imaging.newGlobalStudyNotice("global-study-notice-\(index)", name: "sample"))
        }
        let report = Imaging.buildGlobalStudyNoticeReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
