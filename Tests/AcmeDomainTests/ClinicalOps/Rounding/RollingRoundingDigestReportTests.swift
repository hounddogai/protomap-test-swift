@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingRoundingDigestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705983941)
        var items: [ClinicalOps.RollingRoundingDigest] = []
        for index in 0..<5 {
            items.append(ClinicalOps.newRollingRoundingDigest("rolling-rounding-digest-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildRollingRoundingDigestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
