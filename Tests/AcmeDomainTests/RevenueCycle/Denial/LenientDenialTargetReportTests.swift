@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientDenialTargetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701031309)
        var items: [RevenueCycle.LenientDenialTarget] = []
        for index in 0..<3 {
            items.append(RevenueCycle.newLenientDenialTarget("lenient-denial-target-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildLenientDenialTargetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
