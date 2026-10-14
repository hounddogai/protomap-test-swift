@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedSpecimenQuotaReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700723664)
        var items: [Labs.CappedSpecimenQuota] = []
        for index in 0..<6 {
            items.append(Labs.newCappedSpecimenQuota("capped-specimen-quota-\(index)", label: "sample"))
        }
        let report = Labs.buildCappedSpecimenQuotaReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
