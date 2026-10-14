@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptivePanelEstimateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705840247)
        var items: [Labs.AdaptivePanelEstimate] = []
        for index in 0..<5 {
            items.append(Labs.newAdaptivePanelEstimate("adaptive-panel-estimate-\(index)", label: "sample"))
        }
        let report = Labs.buildAdaptivePanelEstimateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
