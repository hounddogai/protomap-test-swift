@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultDenialCycleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705289076)
        var items: [RevenueCycle.DefaultDenialCycle] = []
        for index in 0..<4 {
            items.append(RevenueCycle.newDefaultDenialCycle("default-denial-cycle-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildDefaultDenialCycleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
