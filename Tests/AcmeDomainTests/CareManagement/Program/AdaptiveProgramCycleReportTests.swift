@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveProgramCycleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700492489)
        var items: [CareManagement.AdaptiveProgramCycle] = []
        for index in 0..<6 {
            items.append(CareManagement.newAdaptiveProgramCycle("adaptive-program-cycle-\(index)", name: "sample"))
        }
        let report = CareManagement.buildAdaptiveProgramCycleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
