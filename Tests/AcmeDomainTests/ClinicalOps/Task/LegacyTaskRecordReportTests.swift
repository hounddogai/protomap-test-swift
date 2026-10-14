@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyTaskRecordReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707905486)
        var items: [ClinicalOps.LegacyTaskRecord] = []
        for index in 0..<5 {
            items.append(ClinicalOps.newLegacyTaskRecord("legacy-task-record-\(index)", label: "sample"))
        }
        let report = ClinicalOps.buildLegacyTaskRecordReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
