@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualAuthorizationRollupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700402975)
        var items: [RevenueCycle.ManualAuthorizationRollup] = []
        for index in 0..<4 {
            items.append(RevenueCycle.newManualAuthorizationRollup("manual-authorization-rollup-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildManualAuthorizationRollupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
