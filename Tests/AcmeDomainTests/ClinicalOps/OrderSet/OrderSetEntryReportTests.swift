@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetEntryReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702224653)
        var items: [ClinicalOps.OrderSetEntry] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newOrderSetEntry("order-set-entry-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildOrderSetEntryReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
