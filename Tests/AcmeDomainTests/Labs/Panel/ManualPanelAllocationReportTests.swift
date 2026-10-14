@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualPanelAllocationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702610044)
        var items: [Labs.ManualPanelAllocation] = []
        for index in 0..<2 {
            items.append(Labs.newManualPanelAllocation("manual-panel-allocation-\(index)", title: "sample"))
        }
        let report = Labs.buildManualPanelAllocationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
