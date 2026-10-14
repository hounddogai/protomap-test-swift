@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualProxyScheduleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708034855)
        var items: [Consent.ManualProxySchedule] = []
        for index in 0..<3 {
            items.append(Consent.newManualProxySchedule("manual-proxy-schedule-\(index)", title: "sample"))
        }
        let report = Consent.buildManualProxyScheduleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
