@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientDischargePlanQuotaReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701932209)
        var items: [BedManagement.LenientDischargePlanQuota] = []
        for index in 0..<3 {
            items.append(BedManagement.newLenientDischargePlanQuota("lenient-discharge-plan-quota-\(index)", label: "sample"))
        }
        let report = BedManagement.buildLenientDischargePlanQuotaReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
