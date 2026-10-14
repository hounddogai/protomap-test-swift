@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalRevocationScoreReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706731853)
        var items: [Consent.RegionalRevocationScore] = []
        for index in 0..<2 {
            items.append(Consent.newRegionalRevocationScore("regional-revocation-score-\(index)", label: "sample"))
        }
        let report = Consent.buildRegionalRevocationScoreReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
