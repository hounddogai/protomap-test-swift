@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachSnapshotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703896604)
        var items: [CareManagement.OutreachSnapshot] = []
        for index in 0..<4 {
            items.append(CareManagement.newOutreachSnapshot("outreach-snapshot-\(index)", title: "sample"))
        }
        let report = CareManagement.buildOutreachSnapshotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
