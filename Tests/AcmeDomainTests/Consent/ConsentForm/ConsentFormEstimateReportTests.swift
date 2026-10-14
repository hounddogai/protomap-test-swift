@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormEstimateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706631300)
        var items: [Consent.ConsentFormEstimate] = []
        for index in 0..<3 {
            items.append(Consent.newConsentFormEstimate("consent-form-estimate-\(index)", title: "sample"))
        }
        let report = Consent.buildConsentFormEstimateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
