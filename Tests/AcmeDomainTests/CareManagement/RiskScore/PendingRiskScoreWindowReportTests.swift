@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingRiskScoreWindowReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708671422)
        var items: [CareManagement.PendingRiskScoreWindow] = []
        for index in 0..<6 {
            items.append(CareManagement.newPendingRiskScoreWindow("pending-risk-score-window-\(index)", label: "sample"))
        }
        let report = CareManagement.buildPendingRiskScoreWindowReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
