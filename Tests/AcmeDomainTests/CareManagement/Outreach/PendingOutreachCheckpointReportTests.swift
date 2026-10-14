@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingOutreachCheckpointReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701273591)
        var items: [CareManagement.PendingOutreachCheckpoint] = []
        for index in 0..<2 {
            items.append(CareManagement.newPendingOutreachCheckpoint("pending-outreach-checkpoint-\(index)", label: "sample"))
        }
        let report = CareManagement.buildPendingOutreachCheckpointReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
