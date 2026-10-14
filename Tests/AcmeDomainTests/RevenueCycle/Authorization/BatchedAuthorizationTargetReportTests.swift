@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedAuthorizationTargetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706294644)
        var items: [RevenueCycle.BatchedAuthorizationTarget] = []
        for index in 0..<3 {
            items.append(RevenueCycle.newBatchedAuthorizationTarget("batched-authorization-target-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildBatchedAuthorizationTargetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
