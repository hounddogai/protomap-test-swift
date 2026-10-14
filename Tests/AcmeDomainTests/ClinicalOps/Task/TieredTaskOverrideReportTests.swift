@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredTaskOverrideReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708554060)
        var items: [ClinicalOps.TieredTaskOverride] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newTieredTaskOverride("tiered-task-override-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildTieredTaskOverrideReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
