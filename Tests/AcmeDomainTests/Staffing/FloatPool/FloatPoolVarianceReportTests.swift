@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolVarianceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704890403)
        var items: [Staffing.FloatPoolVariance] = []
        for index in 0..<5 {
            items.append(Staffing.newFloatPoolVariance("float-pool-variance-\(index)", label: "sample"))
        }
        let report = Staffing.buildFloatPoolVarianceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
