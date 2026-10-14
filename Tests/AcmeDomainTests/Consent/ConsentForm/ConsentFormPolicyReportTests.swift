@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormPolicyReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706345886)
        var items: [Consent.ConsentFormPolicy] = []
        for index in 0..<3 {
            items.append(Consent.newConsentFormPolicy("consent-form-policy-\(index)", name: "sample"))
        }
        let report = Consent.buildConsentFormPolicyReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
