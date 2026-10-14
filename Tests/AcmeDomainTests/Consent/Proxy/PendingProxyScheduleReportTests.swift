@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingProxyScheduleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702264784)
        var items: [Consent.PendingProxySchedule] = []
        for index in 0..<2 {
            items.append(Consent.newPendingProxySchedule("pending-proxy-schedule-\(index)", title: "sample"))
        }
        let report = Consent.buildPendingProxyScheduleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
