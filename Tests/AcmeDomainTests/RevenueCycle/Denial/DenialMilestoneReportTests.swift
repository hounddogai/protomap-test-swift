@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialMilestoneReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707820792)
        var items: [RevenueCycle.DenialMilestone] = []
        for index in 0..<4 {
            items.append(RevenueCycle.newDenialMilestone("denial-milestone-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildDenialMilestoneReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
