@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelSegmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707620639)
        var items: [Labs.PanelSegment] = []
        for index in 0..<2 {
            items.append(Labs.newPanelSegment("panel-segment-\(index)", label: "sample"))
        }
        let report = Labs.buildPanelSegmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
