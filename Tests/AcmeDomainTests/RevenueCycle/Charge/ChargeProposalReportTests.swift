@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeProposalReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708288932)
        var items: [RevenueCycle.ChargeProposal] = []
        for index in 0..<4 {
            items.append(RevenueCycle.newChargeProposal("charge-proposal-\(index)", name: "sample"))
        }
        let report = RevenueCycle.buildChargeProposalReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
