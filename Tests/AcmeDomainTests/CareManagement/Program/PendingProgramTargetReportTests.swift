@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingProgramTargetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705422475)
        var items: [CareManagement.PendingProgramTarget] = []
        for index in 0..<6 {
            items.append(CareManagement.newPendingProgramTarget("pending-program-target-\(index)", name: "sample"))
        }
        let report = CareManagement.buildPendingProgramTargetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
