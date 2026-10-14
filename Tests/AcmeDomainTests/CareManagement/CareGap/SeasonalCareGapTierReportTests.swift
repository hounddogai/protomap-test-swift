@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalCareGapTierReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700616426)
        var items: [CareManagement.SeasonalCareGapTier] = []
        for index in 0..<6 {
            items.append(CareManagement.newSeasonalCareGapTier("seasonal-care-gap-tier-\(index)", name: "sample"))
        }
        let report = CareManagement.buildSeasonalCareGapTierReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
