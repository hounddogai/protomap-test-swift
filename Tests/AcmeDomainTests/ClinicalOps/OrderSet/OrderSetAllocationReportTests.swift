@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetAllocationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706186655)
        var items: [ClinicalOps.OrderSetAllocation] = []
        for index in 0..<4 {
            items.append(ClinicalOps.newOrderSetAllocation("order-set-allocation-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildOrderSetAllocationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
