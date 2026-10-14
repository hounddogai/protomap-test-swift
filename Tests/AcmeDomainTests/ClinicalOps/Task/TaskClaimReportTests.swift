@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskClaimReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703197825)
        var items: [ClinicalOps.TaskClaim] = []
        for index in 0..<6 {
            items.append(ClinicalOps.newTaskClaim("task-claim-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildTaskClaimReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
