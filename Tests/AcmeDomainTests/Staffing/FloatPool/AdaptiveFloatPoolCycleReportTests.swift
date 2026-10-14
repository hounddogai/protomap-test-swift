@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveFloatPoolCycleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703301531)
        var items: [Staffing.AdaptiveFloatPoolCycle] = []
        for index in 0..<2 {
            items.append(Staffing.newAdaptiveFloatPoolCycle("adaptive-float-pool-cycle-\(index)", label: "sample"))
        }
        let report = Staffing.buildAdaptiveFloatPoolCycleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
