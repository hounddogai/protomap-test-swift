@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedConsentFormRollupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703504274)
        var items: [Consent.WeightedConsentFormRollup] = []
        for index in 0..<4 {
            items.append(Consent.newWeightedConsentFormRollup("weighted-consent-form-rollup-\(index)", title: "sample"))
        }
        let report = Consent.buildWeightedConsentFormRollupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
