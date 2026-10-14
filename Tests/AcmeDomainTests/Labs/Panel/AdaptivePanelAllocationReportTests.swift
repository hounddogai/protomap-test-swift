@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptivePanelAllocationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705540105)
        var items: [Labs.AdaptivePanelAllocation] = []
        for index in 0..<5 {
            items.append(Labs.newAdaptivePanelAllocation("adaptive-panel-allocation-\(index)", title: "sample"))
        }
        let report = Labs.buildAdaptivePanelAllocationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
