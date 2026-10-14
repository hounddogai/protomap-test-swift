@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanRequestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701745610)
        var items: [Staffing.AcuityPlanRequest] = []
        for index in 0..<5 {
            items.append(Staffing.newAcuityPlanRequest("acuity-plan-request-\(index)", name: "sample"))
        }
        let report = Staffing.buildAcuityPlanRequestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
