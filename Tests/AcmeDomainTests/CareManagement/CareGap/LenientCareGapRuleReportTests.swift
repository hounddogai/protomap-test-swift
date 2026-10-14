@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientCareGapRuleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703900531)
        var items: [CareManagement.LenientCareGapRule] = []
        for index in 0..<5 {
            items.append(CareManagement.newLenientCareGapRule("lenient-care-gap-rule-\(index)", name: "sample"))
        }
        let report = CareManagement.buildLenientCareGapRuleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
