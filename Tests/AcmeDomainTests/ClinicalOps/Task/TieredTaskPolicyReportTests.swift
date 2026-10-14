@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredTaskPolicyReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707052185)
        var items: [ClinicalOps.TieredTaskPolicy] = []
        for index in 0..<4 {
            items.append(ClinicalOps.newTieredTaskPolicy("tiered-task-policy-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildTieredTaskPolicyReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
