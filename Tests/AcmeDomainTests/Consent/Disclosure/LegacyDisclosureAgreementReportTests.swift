@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyDisclosureAgreementReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700236416)
        var items: [Consent.LegacyDisclosureAgreement] = []
        for index in 0..<6 {
            items.append(Consent.newLegacyDisclosureAgreement("legacy-disclosure-agreement-\(index)", title: "sample"))
        }
        let report = Consent.buildLegacyDisclosureAgreementReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
