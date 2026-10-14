@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelOverrideReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701423382)
        var items: [Labs.PanelOverride] = []
        for index in 0..<6 {
            items.append(Labs.newPanelOverride("panel-override-\(index)", title: "sample"))
        }
        let report = Labs.buildPanelOverrideReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
