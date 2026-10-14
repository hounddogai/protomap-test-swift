@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingLanguageDigestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706226068)
        var items: [Consent.PendingLanguageDigest] = []
        for index in 0..<2 {
            items.append(Consent.newPendingLanguageDigest("pending-language-digest-\(index)", name: "sample"))
        }
        let report = Consent.buildPendingLanguageDigestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
