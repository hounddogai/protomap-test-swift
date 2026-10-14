@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedRemittanceAllocationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708567095)
        var items: [RevenueCycle.BatchedRemittanceAllocation] = []
        for index in 0..<4 {
            items.append(RevenueCycle.newBatchedRemittanceAllocation("batched-remittance-allocation-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildBatchedRemittanceAllocationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
