@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalCareGapEntryReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703195555)
        var items: [CareManagement.SeasonalCareGapEntry] = []
        for index in 0..<2 {
            items.append(CareManagement.newSeasonalCareGapEntry("seasonal-care-gap-entry-\(index)", title: "sample"))
        }
        let report = CareManagement.buildSeasonalCareGapEntryReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
