@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormLedgerReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707769011)
        var items: [Consent.ConsentFormLedger] = []
        for index in 0..<3 {
            items.append(Consent.newConsentFormLedger("consent-form-ledger-\(index)", title: "sample"))
        }
        let report = Consent.buildConsentFormLedgerReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
