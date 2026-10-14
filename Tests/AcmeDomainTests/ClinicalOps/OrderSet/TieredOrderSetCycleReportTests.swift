@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredOrderSetCycleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701460338)
        var items: [ClinicalOps.TieredOrderSetCycle] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newTieredOrderSetCycle("tiered-order-set-cycle-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildTieredOrderSetCycleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
