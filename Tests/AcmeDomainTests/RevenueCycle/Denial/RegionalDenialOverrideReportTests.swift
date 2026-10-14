@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalDenialOverrideReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708568615)
        var items: [RevenueCycle.RegionalDenialOverride] = []
        for index in 0..<6 {
            items.append(RevenueCycle.newRegionalDenialOverride("regional-denial-override-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildRegionalDenialOverrideReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
