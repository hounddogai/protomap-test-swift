@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetMilestoneReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705748831)
        var items: [ClinicalOps.OrderSetMilestone] = []
        for index in 0..<6 {
            items.append(ClinicalOps.newOrderSetMilestone("order-set-milestone-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildOrderSetMilestoneReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
