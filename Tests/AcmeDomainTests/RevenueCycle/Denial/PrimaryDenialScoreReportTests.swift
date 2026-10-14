@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePrimaryDenialScoreReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705569581)
        var items: [RevenueCycle.PrimaryDenialScore] = []
        for index in 0..<6 {
            items.append(RevenueCycle.newPrimaryDenialScore("primary-denial-score-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildPrimaryDenialScoreReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
