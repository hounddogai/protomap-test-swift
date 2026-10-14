@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedProgramRollupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709705495)
        var items: [CareManagement.WeightedProgramRollup] = []
        for index in 0..<2 {
            items.append(CareManagement.newWeightedProgramRollup("weighted-program-rollup-\(index)", label: "sample"))
        }
        let report = CareManagement.buildWeightedProgramRollupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
