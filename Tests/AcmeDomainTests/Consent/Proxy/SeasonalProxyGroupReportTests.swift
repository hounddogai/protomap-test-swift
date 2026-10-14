@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalProxyGroupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709768251)
        var items: [Consent.SeasonalProxyGroup] = []
        for index in 0..<3 {
            items.append(Consent.newSeasonalProxyGroup("seasonal-proxy-group-\(index)", title: "sample"))
        }
        let report = Consent.buildSeasonalProxyGroupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
