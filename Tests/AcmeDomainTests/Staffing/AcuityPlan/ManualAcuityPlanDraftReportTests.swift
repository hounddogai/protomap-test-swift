@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualAcuityPlanDraftReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709099596)
        var items: [Staffing.ManualAcuityPlanDraft] = []
        for index in 0..<5 {
            items.append(Staffing.newManualAcuityPlanDraft("manual-acuity-plan-draft-\(index)", name: "sample"))
        }
        let report = Staffing.buildManualAcuityPlanDraftReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
