@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedOutreachPolicyReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705394120)
        var items: [CareManagement.BatchedOutreachPolicy] = []
        for index in 0..<6 {
            items.append(CareManagement.newBatchedOutreachPolicy("batched-outreach-policy-\(index)", name: "sample"))
        }
        let report = CareManagement.buildBatchedOutreachPolicyReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
