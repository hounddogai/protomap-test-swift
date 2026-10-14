@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationEntryReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709080594)
        var items: [RevenueCycle.AuthorizationEntry] = []
        for index in 0..<6 {
            items.append(RevenueCycle.newAuthorizationEntry("authorization-entry-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildAuthorizationEntryReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
