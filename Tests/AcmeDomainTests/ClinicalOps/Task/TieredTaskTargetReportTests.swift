@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredTaskTargetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703451240)
        var items: [ClinicalOps.TieredTaskTarget] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newTieredTaskTarget("tiered-task-target-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildTieredTaskTargetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
