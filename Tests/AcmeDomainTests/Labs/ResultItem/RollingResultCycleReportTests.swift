@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingResultCycleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700980824)
        var items: [Labs.RollingResultCycle] = []
        for index in 0..<3 {
            items.append(Labs.newRollingResultCycle("rolling-result-cycle-\(index)", title: "sample"))
        }
        let report = Labs.buildRollingResultCycleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
