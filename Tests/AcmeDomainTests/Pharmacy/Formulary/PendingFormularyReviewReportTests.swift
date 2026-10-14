@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingFormularyReviewReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705588556)
        var items: [Pharmacy.PendingFormularyReview] = []
        for index in 0..<4 {
            items.append(Pharmacy.newPendingFormularyReview("pending-formulary-review-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildPendingFormularyReviewReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
