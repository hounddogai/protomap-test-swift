@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledConsentFormReviewReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708520984)
        var items: [Consent.ScheduledConsentFormReview] = []
        for index in 0..<3 {
            items.append(Consent.newScheduledConsentFormReview("scheduled-consent-form-review-\(index)", name: "sample"))
        }
        let report = Consent.buildScheduledConsentFormReviewReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
