@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackPanelDigestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707250220)
        var items: [Labs.FallbackPanelDigest] = []
        for index in 0..<5 {
            items.append(Labs.newFallbackPanelDigest("fallback-panel-digest-\(index)", title: "sample"))
        }
        let report = Labs.buildFallbackPanelDigestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
