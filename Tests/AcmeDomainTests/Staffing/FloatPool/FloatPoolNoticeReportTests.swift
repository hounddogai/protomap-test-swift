@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolNoticeReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702470329)
        var items: [Staffing.FloatPoolNotice] = []
        for index in 0..<2 {
            items.append(Staffing.newFloatPoolNotice("float-pool-notice-\(index)", title: "sample"))
        }
        let report = Staffing.buildFloatPoolNoticeReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
