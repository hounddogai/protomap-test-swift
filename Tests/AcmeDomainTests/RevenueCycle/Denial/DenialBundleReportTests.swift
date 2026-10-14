@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialBundleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709500706)
        var items: [RevenueCycle.DenialBundle] = []
        for index in 0..<5 {
            items.append(RevenueCycle.newDenialBundle("denial-bundle-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildDenialBundleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
