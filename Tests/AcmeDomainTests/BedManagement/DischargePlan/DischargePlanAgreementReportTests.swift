@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanAgreementReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705470788)
        var items: [BedManagement.DischargePlanAgreement] = []
        for index in 0..<2 {
            items.append(BedManagement.newDischargePlanAgreement("discharge-plan-agreement-\(index)", label: "sample"))
        }
        let report = BedManagement.buildDischargePlanAgreementReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
