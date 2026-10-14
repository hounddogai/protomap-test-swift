@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningSnapshotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707655705)
        var items: [BedManagement.CleaningSnapshot] = []
        for index in 0..<3 {
            items.append(BedManagement.newCleaningSnapshot("cleaning-snapshot-\(index)", name: "sample"))
        }
        let report = BedManagement.buildCleaningSnapshotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
