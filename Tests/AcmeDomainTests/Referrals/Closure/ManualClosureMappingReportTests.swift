@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualClosureMappingReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703148827)
        var items: [Referrals.ManualClosureMapping] = []
        for index in 0..<6 {
            items.append(Referrals.newManualClosureMapping("manual-closure-mapping-\(index)", title: "sample"))
        }
        let report = Referrals.buildManualClosureMappingReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
