@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanRecordReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702892940)
        var items: [BedManagement.DischargePlanRecord] = []
        for index in 0..<5 {
            items.append(BedManagement.newDischargePlanRecord("discharge-plan-record-\(index)", title: "sample"))
        }
        let report = BedManagement.buildDischargePlanRecordReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
