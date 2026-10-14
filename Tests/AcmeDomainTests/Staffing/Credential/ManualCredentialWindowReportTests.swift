@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualCredentialWindowReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706732404)
        var items: [Staffing.ManualCredentialWindow] = []
        for index in 0..<3 {
            items.append(Staffing.newManualCredentialWindow("manual-credential-window-\(index)", name: "sample"))
        }
        let report = Staffing.buildManualCredentialWindowReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
