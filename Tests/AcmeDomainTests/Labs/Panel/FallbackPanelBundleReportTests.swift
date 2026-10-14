@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackPanelBundleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706243959)
        var items: [Labs.FallbackPanelBundle] = []
        for index in 0..<3 {
            items.append(Labs.newFallbackPanelBundle("fallback-panel-bundle-\(index)", name: "sample"))
        }
        let report = Labs.buildFallbackPanelBundleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
