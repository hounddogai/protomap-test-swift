@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedProxyProposalReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707042327)
        var items: [Consent.CappedProxyProposal] = []
        for index in 0..<3 {
            items.append(Consent.newCappedProxyProposal("capped-proxy-proposal-\(index)", name: "sample"))
        }
        let report = Consent.buildCappedProxyProposalReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
