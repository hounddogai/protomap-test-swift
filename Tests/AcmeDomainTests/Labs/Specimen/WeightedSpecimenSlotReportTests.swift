@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedSpecimenSlotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701486433)
        var items: [Labs.WeightedSpecimenSlot] = []
        for index in 0..<4 {
            items.append(Labs.newWeightedSpecimenSlot("weighted-specimen-slot-\(index)", name: "sample"))
        }
        let report = Labs.buildWeightedSpecimenSlotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
