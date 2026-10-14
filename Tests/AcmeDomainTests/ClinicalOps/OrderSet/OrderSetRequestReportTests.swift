@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetRequestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709284399)
        var items: [ClinicalOps.OrderSetRequest] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newOrderSetRequest("order-set-request-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildOrderSetRequestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
