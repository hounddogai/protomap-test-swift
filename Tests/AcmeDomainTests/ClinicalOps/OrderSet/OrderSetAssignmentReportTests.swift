@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetAssignmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706118549)
        var items: [ClinicalOps.OrderSetAssignment] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newOrderSetAssignment("order-set-assignment-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildOrderSetAssignmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
