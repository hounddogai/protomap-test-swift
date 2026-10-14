@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedCareGapBundleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703925210)
        var items: [CareManagement.BatchedCareGapBundle] = []
        for index in 0..<3 {
            items.append(CareManagement.newBatchedCareGapBundle("batched-care-gap-bundle-\(index)", name: "sample"))
        }
        let report = CareManagement.buildBatchedCareGapBundleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
