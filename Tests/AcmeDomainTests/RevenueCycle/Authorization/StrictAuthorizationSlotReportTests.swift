@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictAuthorizationSlotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709476580)
        var items: [RevenueCycle.StrictAuthorizationSlot] = []
        for index in 0..<6 {
            items.append(RevenueCycle.newStrictAuthorizationSlot("strict-authorization-slot-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildStrictAuthorizationSlotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
