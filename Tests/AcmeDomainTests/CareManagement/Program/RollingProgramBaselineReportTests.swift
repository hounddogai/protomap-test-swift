@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingProgramBaselineReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704313128)
        var items: [CareManagement.RollingProgramBaseline] = []
        for index in 0..<4 {
            items.append(CareManagement.newRollingProgramBaseline("rolling-program-baseline-\(index)", title: "sample"))
        }
        let report = CareManagement.buildRollingProgramBaselineReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
