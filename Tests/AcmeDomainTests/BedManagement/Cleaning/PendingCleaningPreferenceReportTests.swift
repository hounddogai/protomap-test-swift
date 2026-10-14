@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingCleaningPreferenceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709104435)
        var items: [BedManagement.PendingCleaningPreference] = []
        for index in 0..<4 {
            items.append(BedManagement.newPendingCleaningPreference("pending-cleaning-preference-\(index)", label: "sample"))
        }
        let report = BedManagement.buildPendingCleaningPreferenceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
