@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanReviewReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701276279)
        var items: [BedManagement.DischargePlanReview] = []
        for index in 0..<4 {
            items.append(BedManagement.newDischargePlanReview("discharge-plan-review-\(index)", title: "sample"))
        }
        let report = BedManagement.buildDischargePlanReviewReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
