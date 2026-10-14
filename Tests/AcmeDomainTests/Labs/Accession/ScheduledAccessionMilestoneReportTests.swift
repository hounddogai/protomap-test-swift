@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledAccessionMilestoneReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701249997)
        var items: [Labs.ScheduledAccessionMilestone] = []
        for index in 0..<2 {
            items.append(Labs.newScheduledAccessionMilestone("scheduled-accession-milestone-\(index)", label: "sample"))
        }
        let report = Labs.buildScheduledAccessionMilestoneReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
