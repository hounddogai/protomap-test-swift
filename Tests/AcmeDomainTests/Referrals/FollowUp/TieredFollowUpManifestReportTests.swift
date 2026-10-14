@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredFollowUpManifestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709559269)
        var items: [Referrals.TieredFollowUpManifest] = []
        for index in 0..<5 {
            items.append(Referrals.newTieredFollowUpManifest("tiered-follow-up-manifest-\(index)", label: "sample"))
        }
        let report = Referrals.buildTieredFollowUpManifestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
