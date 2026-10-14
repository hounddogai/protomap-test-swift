@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedRiskScoreNoticeReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709554918)
        var items: [CareManagement.CappedRiskScoreNotice] = []
        for index in 0..<5 {
            items.append(CareManagement.newCappedRiskScoreNotice("capped-risk-score-notice-\(index)", label: "sample"))
        }
        let report = CareManagement.buildCappedRiskScoreNoticeReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
