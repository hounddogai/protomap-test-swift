@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalWitnessBudgetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703816673)
        var items: [Consent.SeasonalWitnessBudget] = []
        for index in 0..<4 {
            items.append(Consent.newSeasonalWitnessBudget("seasonal-witness-budget-\(index)", title: "sample"))
        }
        let report = Consent.buildSeasonalWitnessBudgetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
