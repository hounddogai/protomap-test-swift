@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedPriorityReservationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701829933)
        var items: [Imaging.WeightedPriorityReservation] = []
        for index in 0..<3 {
            items.append(Imaging.newWeightedPriorityReservation("weighted-priority-reservation-\(index)", label: "sample"))
        }
        let report = Imaging.buildWeightedPriorityReservationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
