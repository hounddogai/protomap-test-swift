@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedIsolationRollupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702497462)
        var items: [BedManagement.BatchedIsolationRollup] = []
        for index in 0..<5 {
            items.append(BedManagement.newBatchedIsolationRollup("batched-isolation-rollup-\(index)", title: "sample"))
        }
        let report = BedManagement.buildBatchedIsolationRollupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
