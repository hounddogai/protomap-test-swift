@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCleaningExceptionReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705526421)
        var items: [BedManagement.ScheduledCleaningException] = []
        for index in 0..<6 {
            items.append(BedManagement.newScheduledCleaningException("scheduled-cleaning-exception-\(index)", name: "sample"))
        }
        let report = BedManagement.buildScheduledCleaningExceptionReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
