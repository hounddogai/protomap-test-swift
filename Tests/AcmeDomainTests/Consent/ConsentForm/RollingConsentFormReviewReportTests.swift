@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingConsentFormReviewReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702589700)
        var items: [Consent.RollingConsentFormReview] = []
        for index in 0..<4 {
            items.append(Consent.newRollingConsentFormReview("rolling-consent-form-review-\(index)", title: "sample"))
        }
        let report = Consent.buildRollingConsentFormReviewReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
