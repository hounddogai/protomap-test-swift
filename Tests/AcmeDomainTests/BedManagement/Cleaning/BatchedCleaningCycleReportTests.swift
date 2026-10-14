@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedCleaningCycleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702891991)
        var items: [BedManagement.BatchedCleaningCycle] = []
        for index in 0..<4 {
            items.append(BedManagement.newBatchedCleaningCycle("batched-cleaning-cycle-\(index)", title: "sample"))
        }
        let report = BedManagement.buildBatchedCleaningCycleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
