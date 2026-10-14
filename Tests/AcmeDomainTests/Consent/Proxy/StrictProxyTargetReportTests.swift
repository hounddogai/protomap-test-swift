@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictProxyTargetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702024827)
        var items: [Consent.StrictProxyTarget] = []
        for index in 0..<4 {
            items.append(Consent.newStrictProxyTarget("strict-proxy-target-\(index)", label: "sample"))
        }
        let report = Consent.buildStrictProxyTargetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
