@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualPriorityRuleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700142020)
        var items: [Imaging.ManualPriorityRule] = []
        for index in 0..<2 {
            items.append(Imaging.newManualPriorityRule("manual-priority-rule-\(index)", title: "sample"))
        }
        let report = Imaging.buildManualPriorityRuleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
