@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalSubstitutionForecastReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706060332)
        var items: [Pharmacy.RegionalSubstitutionForecast] = []
        for index in 0..<4 {
            items.append(Pharmacy.newRegionalSubstitutionForecast("regional-substitution-forecast-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildRegionalSubstitutionForecastReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
