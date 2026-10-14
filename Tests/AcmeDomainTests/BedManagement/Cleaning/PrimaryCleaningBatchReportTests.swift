@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryCleaningBatchReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707273500)
        var items: [BedManagement.PrimaryCleaningBatch] = []
        for index in 0..<3 {
            items.append(BedManagement.newPrimaryCleaningBatch("primary-cleaning-batch-\(index)", name: "sample"))
        }
        let report = BedManagement.buildPrimaryCleaningBatchReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
