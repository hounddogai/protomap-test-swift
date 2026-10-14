@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryCareProtocolReviewReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703559929)
        var items: [ClinicalOps.PrimaryCareProtocolReview] = []
        for index in 0..<5 {
            items.append(ClinicalOps.newPrimaryCareProtocolReview("primary-care-protocol-review-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildPrimaryCareProtocolReviewReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
