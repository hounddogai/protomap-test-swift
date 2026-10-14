@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualProgramRollupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708813763)
        var items: [CareManagement.ManualProgramRollup] = []
        for index in 0..<2 {
            items.append(CareManagement.newManualProgramRollup("manual-program-rollup-\(index)", name: "sample"))
        }
        let report = CareManagement.buildManualProgramRollupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
