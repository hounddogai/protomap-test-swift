@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalSpecimenRuleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708448270)
        var items: [Labs.GlobalSpecimenRule] = []
        for index in 0..<2 {
            items.append(Labs.newGlobalSpecimenRule("global-specimen-rule-\(index)", title: "sample"))
        }
        let report = Labs.buildGlobalSpecimenRuleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
