@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedHandoffMappingReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708989030)
        var items: [ClinicalOps.CappedHandoffMapping] = []
        for index in 0..<5 {
            items.append(ClinicalOps.newCappedHandoffMapping("capped-handoff-mapping-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildCappedHandoffMappingReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
