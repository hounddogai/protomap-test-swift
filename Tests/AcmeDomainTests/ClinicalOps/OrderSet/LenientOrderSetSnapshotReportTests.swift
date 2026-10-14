@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientOrderSetSnapshotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704243753)
        var items: [ClinicalOps.LenientOrderSetSnapshot] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newLenientOrderSetSnapshot("lenient-order-set-snapshot-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildLenientOrderSetSnapshotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
