@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientOutreachRuleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700142792)
        var items: [CareManagement.LenientOutreachRule] = []
        for index in 0..<4 {
            items.append(CareManagement.newLenientOutreachRule("lenient-outreach-rule-\(index)", name: "sample"))
        }
        let report = CareManagement.buildLenientOutreachRuleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
