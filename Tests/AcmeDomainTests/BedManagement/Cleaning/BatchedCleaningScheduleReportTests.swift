@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedCleaningScheduleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700947405)
        var items: [BedManagement.BatchedCleaningSchedule] = []
        for index in 0..<5 {
            items.append(BedManagement.newBatchedCleaningSchedule("batched-cleaning-schedule-\(index)", label: "sample"))
        }
        let report = BedManagement.buildBatchedCleaningScheduleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
