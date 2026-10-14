@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictPanelPolicyReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708033904)
        var items: [Labs.StrictPanelPolicy] = []
        for index in 0..<3 {
            items.append(Labs.newStrictPanelPolicy("strict-panel-policy-\(index)", title: "sample"))
        }
        let report = Labs.buildStrictPanelPolicyReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
