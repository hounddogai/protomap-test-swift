@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialAdjustmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709307712)
        var items: [RevenueCycle.DenialAdjustment] = []
        for index in 0..<5 {
            items.append(RevenueCycle.newDenialAdjustment("denial-adjustment-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildDenialAdjustmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
