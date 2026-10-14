@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialVarianceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701817818)
        var items: [RevenueCycle.DenialVariance] = []
        for index in 0..<4 {
            items.append(RevenueCycle.newDenialVariance("denial-variance-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildDenialVarianceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
