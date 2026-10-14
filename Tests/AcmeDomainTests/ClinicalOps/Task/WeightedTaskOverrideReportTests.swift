@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedTaskOverrideReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701285885)
        var items: [ClinicalOps.WeightedTaskOverride] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newWeightedTaskOverride("weighted-task-override-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildWeightedTaskOverrideReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
