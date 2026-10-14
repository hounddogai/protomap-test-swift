@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultProxyScoreReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701817000)
        var items: [Consent.DefaultProxyScore] = []
        for index in 0..<4 {
            items.append(Consent.newDefaultProxyScore("default-proxy-score-\(index)", label: "sample"))
        }
        let report = Consent.buildDefaultProxyScoreReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
