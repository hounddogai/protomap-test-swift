@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultAuthorizationTargetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702889424)
        var items: [RevenueCycle.DefaultAuthorizationTarget] = []
        for index in 0..<3 {
            items.append(RevenueCycle.newDefaultAuthorizationTarget("default-authorization-target-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildDefaultAuthorizationTargetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
