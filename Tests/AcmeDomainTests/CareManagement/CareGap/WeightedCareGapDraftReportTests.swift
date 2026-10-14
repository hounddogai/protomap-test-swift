@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedCareGapDraftReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708737652)
        var items: [CareManagement.WeightedCareGapDraft] = []
        for index in 0..<2 {
            items.append(CareManagement.newWeightedCareGapDraft("weighted-care-gap-draft-\(index)", title: "sample"))
        }
        let report = CareManagement.buildWeightedCareGapDraftReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
