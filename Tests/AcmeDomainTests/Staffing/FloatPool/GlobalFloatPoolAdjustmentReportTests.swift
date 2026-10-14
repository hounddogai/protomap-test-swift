@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalFloatPoolAdjustmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702854439)
        var items: [Staffing.GlobalFloatPoolAdjustment] = []
        for index in 0..<5 {
            items.append(Staffing.newGlobalFloatPoolAdjustment("global-float-pool-adjustment-\(index)", label: "sample"))
        }
        let report = Staffing.buildGlobalFloatPoolAdjustmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
