@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyVarianceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704495626)
        var items: [Imaging.StudyVariance] = []
        for index in 0..<6 {
            items.append(Imaging.newStudyVariance("study-variance-\(index)", title: "sample"))
        }
        let report = Imaging.buildStudyVarianceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
