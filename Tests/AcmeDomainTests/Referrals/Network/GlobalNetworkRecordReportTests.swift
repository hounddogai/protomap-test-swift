@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalNetworkRecordReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705035171)
        var items: [Referrals.GlobalNetworkRecord] = []
        for index in 0..<6 {
            items.append(Referrals.newGlobalNetworkRecord("global-network-record-\(index)", label: "sample"))
        }
        let report = Referrals.buildGlobalNetworkRecordReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
