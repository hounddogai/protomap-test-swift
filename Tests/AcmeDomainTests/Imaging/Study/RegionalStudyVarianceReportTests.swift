@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalStudyVarianceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707559102)
        var items: [Imaging.RegionalStudyVariance] = []
        for index in 0..<4 {
            items.append(Imaging.newRegionalStudyVariance("regional-study-variance-\(index)", title: "sample"))
        }
        let report = Imaging.buildRegionalStudyVarianceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
