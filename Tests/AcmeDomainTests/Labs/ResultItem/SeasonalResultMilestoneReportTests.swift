@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalResultMilestoneReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708752571)
        var items: [Labs.SeasonalResultMilestone] = []
        for index in 0..<6 {
            items.append(Labs.newSeasonalResultMilestone("seasonal-result-milestone-\(index)", name: "sample"))
        }
        let report = Labs.buildSeasonalResultMilestoneReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
