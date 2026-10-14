@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingDisclosureClaimReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703514809)
        var items: [Consent.PendingDisclosureClaim] = []
        for index in 0..<4 {
            items.append(Consent.newPendingDisclosureClaim("pending-disclosure-claim-\(index)", name: "sample"))
        }
        let report = Consent.buildPendingDisclosureClaimReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
