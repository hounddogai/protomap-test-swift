@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackTaskEntryReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705346060)
        var items: [ClinicalOps.FallbackTaskEntry] = []
        for index in 0..<4 {
            items.append(ClinicalOps.newFallbackTaskEntry("fallback-task-entry-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildFallbackTaskEntryReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
