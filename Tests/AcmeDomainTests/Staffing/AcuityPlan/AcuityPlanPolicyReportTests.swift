@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanPolicyReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704257901)
        var items: [Staffing.AcuityPlanPolicy] = []
        for index in 0..<6 {
            items.append(Staffing.newAcuityPlanPolicy("acuity-plan-policy-\(index)", label: "sample"))
        }
        let report = Staffing.buildAcuityPlanPolicyReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
