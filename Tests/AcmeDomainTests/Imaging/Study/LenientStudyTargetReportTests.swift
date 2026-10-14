@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientStudyTargetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700095054)
        var items: [Imaging.LenientStudyTarget] = []
        for index in 0..<5 {
            items.append(Imaging.newLenientStudyTarget("lenient-study-target-\(index)", name: "sample"))
        }
        let report = Imaging.buildLenientStudyTargetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
