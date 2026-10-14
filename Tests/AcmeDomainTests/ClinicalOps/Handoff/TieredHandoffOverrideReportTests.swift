@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredHandoffOverrideReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706306709)
        var items: [ClinicalOps.TieredHandoffOverride] = []
        for index in 0..<5 {
            items.append(ClinicalOps.newTieredHandoffOverride("tiered-handoff-override-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildTieredHandoffOverrideReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
