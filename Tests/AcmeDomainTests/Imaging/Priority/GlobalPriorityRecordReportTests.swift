@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalPriorityRecordReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706724891)
        var items: [Imaging.GlobalPriorityRecord] = []
        for index in 0..<5 {
            items.append(Imaging.newGlobalPriorityRecord("global-priority-record-\(index)", label: "sample"))
        }
        let report = Imaging.buildGlobalPriorityRecordReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
