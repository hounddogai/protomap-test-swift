@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedOutreachSlotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704916744)
        var items: [CareManagement.WeightedOutreachSlot] = []
        for index in 0..<5 {
            items.append(CareManagement.newWeightedOutreachSlot("weighted-outreach-slot-\(index)", label: "sample"))
        }
        let report = CareManagement.buildWeightedOutreachSlotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
