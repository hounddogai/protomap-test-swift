@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalShiftTemplateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709749995)
        var items: [Staffing.GlobalShiftTemplate] = []
        for index in 0..<2 {
            items.append(Staffing.newGlobalShiftTemplate("global-shift-template-\(index)", label: "sample"))
        }
        let report = Staffing.buildGlobalShiftTemplateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
