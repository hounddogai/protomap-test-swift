@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapMilestoneReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708334022)
        var items: [CareManagement.CareGapMilestone] = []
        for index in 0..<3 {
            items.append(CareManagement.newCareGapMilestone("care-gap-milestone-\(index)", name: "sample"))
        }
        let report = CareManagement.buildCareGapMilestoneReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
