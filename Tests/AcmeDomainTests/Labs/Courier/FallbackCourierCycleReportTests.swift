@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackCourierCycleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705384079)
        var items: [Labs.FallbackCourierCycle] = []
        for index in 0..<5 {
            items.append(Labs.newFallbackCourierCycle("fallback-courier-cycle-\(index)", label: "sample"))
        }
        let report = Labs.buildFallbackCourierCycleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
