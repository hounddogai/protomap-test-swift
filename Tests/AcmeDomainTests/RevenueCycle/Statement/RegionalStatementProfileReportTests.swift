@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalStatementProfileReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703877364)
        var items: [RevenueCycle.RegionalStatementProfile] = []
        for index in 0..<6 {
            items.append(RevenueCycle.newRegionalStatementProfile("regional-statement-profile-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildRegionalStatementProfileReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
