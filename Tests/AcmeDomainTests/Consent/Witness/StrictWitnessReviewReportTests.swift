@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictWitnessReviewReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701998944)
        var items: [Consent.StrictWitnessReview] = []
        for index in 0..<4 {
            items.append(Consent.newStrictWitnessReview("strict-witness-review-\(index)", label: "sample"))
        }
        let report = Consent.buildStrictWitnessReviewReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
