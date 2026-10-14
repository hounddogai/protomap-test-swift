@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryAcuityPlanPolicyReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701403802)
        var items: [Staffing.PrimaryAcuityPlanPolicy] = []
        for index in 0..<2 {
            items.append(Staffing.newPrimaryAcuityPlanPolicy("primary-acuity-plan-policy-\(index)", label: "sample"))
        }
        let report = Staffing.buildPrimaryAcuityPlanPolicyReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
