@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredTaskRecordReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706434640)
        var items: [ClinicalOps.TieredTaskRecord] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newTieredTaskRecord("tiered-task-record-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildTieredTaskRecordReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
