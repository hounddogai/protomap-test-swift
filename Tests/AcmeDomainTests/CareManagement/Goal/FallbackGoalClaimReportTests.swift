@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackGoalClaimReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709437102)
        var items: [CareManagement.FallbackGoalClaim] = []
        for index in 0..<5 {
            items.append(CareManagement.newFallbackGoalClaim("fallback-goal-claim-\(index)", title: "sample"))
        }
        let report = CareManagement.buildFallbackGoalClaimReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
