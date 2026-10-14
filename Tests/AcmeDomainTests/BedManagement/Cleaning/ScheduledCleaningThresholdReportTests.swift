@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCleaningThresholdReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706496951)
        var items: [BedManagement.ScheduledCleaningThreshold] = []
        for index in 0..<4 {
            items.append(BedManagement.newScheduledCleaningThreshold("scheduled-cleaning-threshold-\(index)", name: "sample"))
        }
        let report = BedManagement.buildScheduledCleaningThresholdReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
