@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalNetworkGroupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702959807)
        var items: [Referrals.SeasonalNetworkGroup] = []
        for index in 0..<3 {
            items.append(Referrals.newSeasonalNetworkGroup("seasonal-network-group-\(index)", title: "sample"))
        }
        let report = Referrals.buildSeasonalNetworkGroupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
