@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictOrderSetRollupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704196948)
        var items: [ClinicalOps.StrictOrderSetRollup] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newStrictOrderSetRollup("strict-order-set-rollup-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildStrictOrderSetRollupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
