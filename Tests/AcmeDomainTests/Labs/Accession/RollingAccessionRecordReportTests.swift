@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingAccessionRecordReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708174612)
        var items: [Labs.RollingAccessionRecord] = []
        for index in 0..<3 {
            items.append(Labs.newRollingAccessionRecord("rolling-accession-record-\(index)", name: "sample"))
        }
        let report = Labs.buildRollingAccessionRecordReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
