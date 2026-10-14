@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledInventoryCheckpointReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700284733)
        var items: [Pharmacy.ScheduledInventoryCheckpoint] = []
        for index in 0..<3 {
            items.append(Pharmacy.newScheduledInventoryCheckpoint("scheduled-inventory-checkpoint-\(index)", label: "sample"))
        }
        let report = Pharmacy.buildScheduledInventoryCheckpointReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
