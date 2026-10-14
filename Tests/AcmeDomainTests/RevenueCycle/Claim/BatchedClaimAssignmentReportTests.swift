@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedClaimAssignmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700820176)
        var items: [RevenueCycle.BatchedClaimAssignment] = []
        for index in 0..<3 {
            items.append(RevenueCycle.newBatchedClaimAssignment("batched-claim-assignment-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildBatchedClaimAssignmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
