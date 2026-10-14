@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedCourierReviewReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703811904)
        var items: [Labs.CappedCourierReview] = []
        for index in 0..<5 {
            items.append(Labs.newCappedCourierReview("capped-courier-review-\(index)", title: "sample"))
        }
        let report = Labs.buildCappedCourierReviewReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
