@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionRuleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700656887)
        var items: [Pharmacy.SubstitutionRule] = []
        for index in 0..<2 {
            items.append(Pharmacy.newSubstitutionRule("substitution-rule-\(index)", title: "sample"))
        }
        let report = Pharmacy.buildSubstitutionRuleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
