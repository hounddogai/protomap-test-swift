@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingPanelTemplateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709418862)
        var items: [Labs.PendingPanelTemplate] = []
        for index in 0..<2 {
            items.append(Labs.newPendingPanelTemplate("pending-panel-template-\(index)", name: "sample"))
        }
        let report = Labs.buildPendingPanelTemplateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
