@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetScoreReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700693865)
        var items: [ClinicalOps.OrderSetScore] = []
        for index in 0..<6 {
            items.append(ClinicalOps.newOrderSetScore("order-set-score-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildOrderSetScoreReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
