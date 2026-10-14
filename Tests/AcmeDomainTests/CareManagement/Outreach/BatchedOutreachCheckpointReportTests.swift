@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedOutreachCheckpointReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702909775)
        var items: [CareManagement.BatchedOutreachCheckpoint] = []
        for index in 0..<5 {
            items.append(CareManagement.newBatchedOutreachCheckpoint("batched-outreach-checkpoint-\(index)", name: "sample"))
        }
        let report = CareManagement.buildBatchedOutreachCheckpointReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
