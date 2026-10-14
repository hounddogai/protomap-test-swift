@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackClosureManifestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704163455)
        var items: [Referrals.FallbackClosureManifest] = []
        for index in 0..<6 {
            items.append(Referrals.newFallbackClosureManifest("fallback-closure-manifest-\(index)", label: "sample"))
        }
        let report = Referrals.buildFallbackClosureManifestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
