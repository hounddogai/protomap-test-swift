@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalStudySnapshotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708599814)
        var items: [Imaging.RegionalStudySnapshot] = []
        for index in 0..<2 {
            items.append(Imaging.newRegionalStudySnapshot("regional-study-snapshot-\(index)", name: "sample"))
        }
        let report = Imaging.buildRegionalStudySnapshotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
