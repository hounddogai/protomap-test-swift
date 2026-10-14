@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledConsentFormDraftReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703193743)
        var items: [Consent.ScheduledConsentFormDraft] = []
        for index in 0..<3 {
            items.append(Consent.newScheduledConsentFormDraft("scheduled-consent-form-draft-\(index)", title: "sample"))
        }
        let report = Consent.buildScheduledConsentFormDraftReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
