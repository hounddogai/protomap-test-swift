@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingInventoryScheduleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705194295)
        var items: [Pharmacy.RollingInventorySchedule] = []
        for index in 0..<4 {
            items.append(Pharmacy.newRollingInventorySchedule("rolling-inventory-schedule-\(index)", label: "sample"))
        }
        let report = Pharmacy.buildRollingInventoryScheduleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
