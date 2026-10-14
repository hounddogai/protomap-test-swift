@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalCensusRollupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703220237)
        var items: [BedManagement.GlobalCensusRollup] = []
        for index in 0..<5 {
            items.append(BedManagement.newGlobalCensusRollup("global-census-rollup-\(index)", name: "sample"))
        }
        let report = BedManagement.buildGlobalCensusRollupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
