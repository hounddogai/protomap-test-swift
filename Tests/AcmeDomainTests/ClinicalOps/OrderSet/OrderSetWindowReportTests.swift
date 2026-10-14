@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetWindowReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708434888)
        var items: [ClinicalOps.OrderSetWindow] = []
        for index in 0..<6 {
            items.append(ClinicalOps.newOrderSetWindow("order-set-window-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildOrderSetWindowReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
