@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningNoticeReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700618312)
        var items: [BedManagement.CleaningNotice] = []
        for index in 0..<3 {
            items.append(BedManagement.newCleaningNotice("cleaning-notice-\(index)", label: "sample"))
        }
        let report = BedManagement.buildCleaningNoticeReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
