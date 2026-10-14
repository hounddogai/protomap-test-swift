@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingOrderSetGroupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705540632)
        var items: [ClinicalOps.PendingOrderSetGroup] = []
        for index in 0..<5 {
            items.append(ClinicalOps.newPendingOrderSetGroup("pending-order-set-group-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildPendingOrderSetGroupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
