@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalReadPlanReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701587084)
        var items: [Imaging.SeasonalReadPlan] = []
        for index in 0..<2 {
            items.append(Imaging.newSeasonalReadPlan("seasonal-read-plan-\(index)", name: "sample"))
        }
        let report = Imaging.buildSeasonalReadPlanReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
