@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingProxyAuditReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706340653)
        var items: [Consent.RollingProxyAudit] = []
        for index in 0..<4 {
            items.append(Consent.newRollingProxyAudit("rolling-proxy-audit-\(index)", name: "sample"))
        }
        let report = Consent.buildRollingProxyAuditReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
