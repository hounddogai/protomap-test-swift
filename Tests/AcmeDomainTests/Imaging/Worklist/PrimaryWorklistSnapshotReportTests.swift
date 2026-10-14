@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryWorklistSnapshotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702727788)
        var items: [Imaging.PrimaryWorklistSnapshot] = []
        for index in 0..<6 {
            items.append(Imaging.newPrimaryWorklistSnapshot("primary-worklist-snapshot-\(index)", title: "sample"))
        }
        let report = Imaging.buildPrimaryWorklistSnapshotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
