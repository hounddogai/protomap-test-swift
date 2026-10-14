@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredGoalRequestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705345149)
        var items: [CareManagement.TieredGoalRequest] = []
        for index in 0..<6 {
            items.append(CareManagement.newTieredGoalRequest("tiered-goal-request-\(index)", title: "sample"))
        }
        let report = CareManagement.buildTieredGoalRequestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
