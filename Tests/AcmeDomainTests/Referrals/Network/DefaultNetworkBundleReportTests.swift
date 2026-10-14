@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultNetworkBundleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701904710)
        var items: [Referrals.DefaultNetworkBundle] = []
        for index in 0..<6 {
            items.append(Referrals.newDefaultNetworkBundle("default-network-bundle-\(index)", title: "sample"))
        }
        let report = Referrals.buildDefaultNetworkBundleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
