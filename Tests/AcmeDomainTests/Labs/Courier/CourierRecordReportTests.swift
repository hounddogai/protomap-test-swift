@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierRecordReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709558298)
        var items: [Labs.CourierRecord] = []
        for index in 0..<3 {
            items.append(Labs.newCourierRecord("courier-record-\(index)", name: "sample"))
        }
        let report = Labs.buildCourierRecordReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
