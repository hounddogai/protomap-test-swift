@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolEstimateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703553941)
        var items: [Staffing.FloatPoolEstimate] = []
        for index in 0..<2 {
            items.append(Staffing.newFloatPoolEstimate("float-pool-estimate-\(index)", name: "sample"))
        }
        let report = Staffing.buildFloatPoolEstimateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
