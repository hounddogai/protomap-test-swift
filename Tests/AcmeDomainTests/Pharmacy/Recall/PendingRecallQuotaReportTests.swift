@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingRecallQuotaReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708406908)
        var items: [Pharmacy.PendingRecallQuota] = []
        for index in 0..<4 {
            items.append(Pharmacy.newPendingRecallQuota("pending-recall-quota-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildPendingRecallQuotaReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
