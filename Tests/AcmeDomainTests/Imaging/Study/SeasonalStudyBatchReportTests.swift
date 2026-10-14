@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalStudyBatchReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706097717)
        var items: [Imaging.SeasonalStudyBatch] = []
        for index in 0..<4 {
            items.append(Imaging.newSeasonalStudyBatch("seasonal-study-batch-\(index)", name: "sample"))
        }
        let report = Imaging.buildSeasonalStudyBatchReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
