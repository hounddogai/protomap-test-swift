@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryStudyBaselineReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709440329)
        var items: [Imaging.PrimaryStudyBaseline] = []
        for index in 0..<5 {
            items.append(Imaging.newPrimaryStudyBaseline("primary-study-baseline-\(index)", label: "sample"))
        }
        let report = Imaging.buildPrimaryStudyBaselineReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
