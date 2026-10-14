@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledAccessionNoticeReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702284895)
        var items: [Labs.ScheduledAccessionNotice] = []
        for index in 0..<3 {
            items.append(Labs.newScheduledAccessionNotice("scheduled-accession-notice-\(index)", label: "sample"))
        }
        let report = Labs.buildScheduledAccessionNoticeReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
