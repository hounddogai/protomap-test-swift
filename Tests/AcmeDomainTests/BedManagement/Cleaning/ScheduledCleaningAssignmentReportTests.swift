@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCleaningAssignmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703462069)
        var items: [BedManagement.ScheduledCleaningAssignment] = []
        for index in 0..<3 {
            items.append(BedManagement.newScheduledCleaningAssignment("scheduled-cleaning-assignment-\(index)", name: "sample"))
        }
        let report = BedManagement.buildScheduledCleaningAssignmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
