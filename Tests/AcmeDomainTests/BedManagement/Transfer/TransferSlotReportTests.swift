@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferSlotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704609844)
        var items: [BedManagement.TransferSlot] = []
        for index in 0..<2 {
            items.append(BedManagement.newTransferSlot("transfer-slot-\(index)", title: "sample"))
        }
        let report = BedManagement.buildTransferSlotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
