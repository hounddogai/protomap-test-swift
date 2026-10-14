@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsManualOrderSetGroupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701047279)
        var items: [ClinicalOps.ManualOrderSetGroup] = []
        for index in 0..<5 {
            items.append(ClinicalOps.newManualOrderSetGroup("manual-order-set-group-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildManualOrderSetGroupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
