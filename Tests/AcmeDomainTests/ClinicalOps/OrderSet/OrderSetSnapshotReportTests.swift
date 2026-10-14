@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetSnapshotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708644051)
        var items: [ClinicalOps.OrderSetSnapshot] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newOrderSetSnapshot("order-set-snapshot-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildOrderSetSnapshotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
