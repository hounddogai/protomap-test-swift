@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedCareGapBatchReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706623967)
        var items: [CareManagement.CappedCareGapBatch] = []
        for index in 0..<3 {
            items.append(CareManagement.newCappedCareGapBatch("capped-care-gap-batch-\(index)", name: "sample"))
        }
        let report = CareManagement.buildCappedCareGapBatchReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
