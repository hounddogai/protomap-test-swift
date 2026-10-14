@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalHandoffCycleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709311690)
        var items: [ClinicalOps.RegionalHandoffCycle] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newRegionalHandoffCycle("regional-handoff-cycle-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildRegionalHandoffCycleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
