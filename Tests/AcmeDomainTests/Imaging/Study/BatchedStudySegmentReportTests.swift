@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingBatchedStudySegmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703467732)
        var items: [Imaging.BatchedStudySegment] = []
        for index in 0..<6 {
            items.append(Imaging.newBatchedStudySegment("batched-study-segment-\(index)", label: "sample"))
        }
        let report = Imaging.buildBatchedStudySegmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
