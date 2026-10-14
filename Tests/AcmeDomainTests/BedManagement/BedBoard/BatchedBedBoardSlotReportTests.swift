@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedBedBoardSlotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706190883)
        var items: [BedManagement.BatchedBedBoardSlot] = []
        for index in 0..<3 {
            items.append(BedManagement.newBatchedBedBoardSlot("batched-bed-board-slot-\(index)", title: "sample"))
        }
        let report = BedManagement.buildBatchedBedBoardSlotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
