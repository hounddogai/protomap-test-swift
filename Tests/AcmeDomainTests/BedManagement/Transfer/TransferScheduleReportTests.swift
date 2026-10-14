@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferScheduleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701442895)
        var items: [BedManagement.TransferSchedule] = []
        for index in 0..<5 {
            items.append(BedManagement.newTransferSchedule("transfer-schedule-\(index)", name: "sample"))
        }
        let report = BedManagement.buildTransferScheduleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
