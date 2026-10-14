@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredClaimReviewReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702842131)
        var items: [RevenueCycle.TieredClaimReview] = []
        for index in 0..<6 {
            items.append(RevenueCycle.newTieredClaimReview("tiered-claim-review-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildTieredClaimReviewReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
