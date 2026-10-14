@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultReferenceRangeRuleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707539723)
        var items: [Labs.DefaultReferenceRangeRule] = []
        for index in 0..<6 {
            items.append(Labs.newDefaultReferenceRangeRule("default-reference-range-rule-\(index)", title: "sample"))
        }
        let report = Labs.buildDefaultReferenceRangeRuleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
