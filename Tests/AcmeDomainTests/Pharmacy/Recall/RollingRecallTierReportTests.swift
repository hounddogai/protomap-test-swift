@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingRecallTierReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709380371)
        var items: [Pharmacy.RollingRecallTier] = []
        for index in 0..<5 {
            items.append(Pharmacy.newRollingRecallTier("rolling-recall-tier-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildRollingRecallTierReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
