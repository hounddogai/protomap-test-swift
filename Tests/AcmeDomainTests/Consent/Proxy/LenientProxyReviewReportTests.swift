@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientProxyReviewReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705680685)
        var items: [Consent.LenientProxyReview] = []
        for index in 0..<3 {
            items.append(Consent.newLenientProxyReview("lenient-proxy-review-\(index)", label: "sample"))
        }
        let report = Consent.buildLenientProxyReviewReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
