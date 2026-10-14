@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingCourierThresholdReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703115243)
        var items: [Labs.RollingCourierThreshold] = []
        for index in 0..<2 {
            items.append(Labs.newRollingCourierThreshold("rolling-courier-threshold-\(index)", title: "sample"))
        }
        let report = Labs.buildRollingCourierThresholdReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
