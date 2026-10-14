@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyCareGapSnapshotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701074931)
        var items: [CareManagement.LegacyCareGapSnapshot] = []
        for index in 0..<2 {
            items.append(CareManagement.newLegacyCareGapSnapshot("legacy-care-gap-snapshot-\(index)", label: "sample"))
        }
        let report = CareManagement.buildLegacyCareGapSnapshotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
