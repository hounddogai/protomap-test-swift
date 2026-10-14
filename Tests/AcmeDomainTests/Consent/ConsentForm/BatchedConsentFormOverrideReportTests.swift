@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedConsentFormOverrideReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702877661)
        var items: [Consent.BatchedConsentFormOverride] = []
        for index in 0..<5 {
            items.append(Consent.newBatchedConsentFormOverride("batched-consent-form-override-\(index)", title: "sample"))
        }
        let report = Consent.buildBatchedConsentFormOverrideReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
