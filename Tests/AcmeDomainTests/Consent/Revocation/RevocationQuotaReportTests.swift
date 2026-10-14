@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationQuotaReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708967911)
        var items: [Consent.RevocationQuota] = []
        for index in 0..<5 {
            items.append(Consent.newRevocationQuota("revocation-quota-\(index)", label: "sample"))
        }
        let report = Consent.buildRevocationQuotaReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
