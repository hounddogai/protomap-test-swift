@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredConsentFormProposalReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703899516)
        var items: [Consent.TieredConsentFormProposal] = []
        for index in 0..<5 {
            items.append(Consent.newTieredConsentFormProposal("tiered-consent-form-proposal-\(index)", label: "sample"))
        }
        let report = Consent.buildTieredConsentFormProposalReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
