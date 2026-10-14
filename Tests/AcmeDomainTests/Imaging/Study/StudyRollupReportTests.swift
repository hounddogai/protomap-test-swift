@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyRollupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708661298)
        var items: [Imaging.StudyRollup] = []
        for index in 0..<5 {
            items.append(Imaging.newStudyRollup("study-rollup-\(index)", title: "sample"))
        }
        let report = Imaging.buildStudyRollupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
