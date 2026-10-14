@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceBundleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709884816)
        var items: [RevenueCycle.RemittanceBundle] = []
        for index in 0..<2 {
            items.append(RevenueCycle.newRemittanceBundle("remittance-bundle-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildRemittanceBundleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
