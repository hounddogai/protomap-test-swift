@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackNetworkSnapshotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708403166)
        var items: [Referrals.FallbackNetworkSnapshot] = []
        for index in 0..<5 {
            items.append(Referrals.newFallbackNetworkSnapshot("fallback-network-snapshot-\(index)", title: "sample"))
        }
        let report = Referrals.buildFallbackNetworkSnapshotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
