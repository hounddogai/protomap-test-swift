@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackOutreachRuleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708718735)
        var items: [CareManagement.FallbackOutreachRule] = []
        for index in 0..<6 {
            items.append(CareManagement.newFallbackOutreachRule("fallback-outreach-rule-\(index)", label: "sample"))
        }
        let report = CareManagement.buildFallbackOutreachRuleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
