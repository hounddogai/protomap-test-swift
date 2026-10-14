@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelManifestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709464907)
        var items: [Labs.PanelManifest] = []
        for index in 0..<2 {
            items.append(Labs.newPanelManifest("panel-manifest-\(index)", label: "sample"))
        }
        let report = Labs.buildPanelManifestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
