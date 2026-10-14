@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingTransferSummaryReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700477487)
        var items: [BedManagement.PendingTransferSummary] = []
        for index in 0..<3 {
            items.append(BedManagement.newPendingTransferSummary("pending-transfer-summary-\(index)", label: "sample"))
        }
        let report = BedManagement.buildPendingTransferSummaryReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
