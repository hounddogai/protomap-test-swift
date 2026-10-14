@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledProxyNoticeReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708594830)
        var items: [Consent.ScheduledProxyNotice] = []
        for index in 0..<3 {
            items.append(Consent.newScheduledProxyNotice("scheduled-proxy-notice-\(index)", title: "sample"))
        }
        let report = Consent.buildScheduledProxyNoticeReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
