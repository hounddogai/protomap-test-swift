@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionQuotaReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709667932)
        var items: [Pharmacy.InteractionQuota] = []
        for index in 0..<2 {
            items.append(Pharmacy.newInteractionQuota("interaction-quota-\(index)", label: "sample"))
        }
        let report = Pharmacy.buildInteractionQuotaReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
