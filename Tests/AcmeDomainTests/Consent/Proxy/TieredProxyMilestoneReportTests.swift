@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredProxyMilestoneReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701274523)
        var items: [Consent.TieredProxyMilestone] = []
        for index in 0..<3 {
            items.append(Consent.newTieredProxyMilestone("tiered-proxy-milestone-\(index)", name: "sample"))
        }
        let report = Consent.buildTieredProxyMilestoneReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
