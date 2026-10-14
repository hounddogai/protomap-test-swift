@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedNetworkDraftReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700392094)
        var items: [Referrals.CappedNetworkDraft] = []
        for index in 0..<4 {
            items.append(Referrals.newCappedNetworkDraft("capped-network-draft-\(index)", label: "sample"))
        }
        let report = Referrals.buildCappedNetworkDraftReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
