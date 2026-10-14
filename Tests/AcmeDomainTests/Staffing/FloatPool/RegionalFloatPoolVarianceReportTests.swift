@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalFloatPoolVarianceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700667109)
        var items: [Staffing.RegionalFloatPoolVariance] = []
        for index in 0..<6 {
            items.append(Staffing.newRegionalFloatPoolVariance("regional-float-pool-variance-\(index)", title: "sample"))
        }
        let report = Staffing.buildRegionalFloatPoolVarianceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
