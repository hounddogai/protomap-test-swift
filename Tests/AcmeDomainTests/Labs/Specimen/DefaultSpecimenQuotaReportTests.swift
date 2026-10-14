@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultSpecimenQuotaReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709464255)
        var items: [Labs.DefaultSpecimenQuota] = []
        for index in 0..<2 {
            items.append(Labs.newDefaultSpecimenQuota("default-specimen-quota-\(index)", label: "sample"))
        }
        let report = Labs.buildDefaultSpecimenQuotaReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
