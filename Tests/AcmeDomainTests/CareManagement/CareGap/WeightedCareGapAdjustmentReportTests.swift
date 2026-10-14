@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedCareGapAdjustmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705665014)
        var items: [CareManagement.WeightedCareGapAdjustment] = []
        for index in 0..<2 {
            items.append(CareManagement.newWeightedCareGapAdjustment("weighted-care-gap-adjustment-\(index)", title: "sample"))
        }
        let report = CareManagement.buildWeightedCareGapAdjustmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
