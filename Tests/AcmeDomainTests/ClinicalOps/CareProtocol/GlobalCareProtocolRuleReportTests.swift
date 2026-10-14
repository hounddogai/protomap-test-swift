@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalCareProtocolRuleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702896456)
        var items: [ClinicalOps.GlobalCareProtocolRule] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newGlobalCareProtocolRule("global-care-protocol-rule-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildGlobalCareProtocolRuleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
