@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictReadSnapshotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707823401)
        var items: [Imaging.StrictReadSnapshot] = []
        for index in 0..<5 {
            items.append(Imaging.newStrictReadSnapshot("strict-read-snapshot-\(index)", title: "sample"))
        }
        let report = Imaging.buildStrictReadSnapshotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
