@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialCycleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703737989)
        var items: [RevenueCycle.DenialCycle] = []
        for index in 0..<6 {
            items.append(RevenueCycle.newDenialCycle("denial-cycle-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildDenialCycleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
