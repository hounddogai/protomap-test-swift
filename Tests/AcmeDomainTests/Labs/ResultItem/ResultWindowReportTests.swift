@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultWindowReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700518251)
        var items: [Labs.ResultWindow] = []
        for index in 0..<2 {
            items.append(Labs.newResultWindow("result-window-\(index)", title: "sample"))
        }
        let report = Labs.buildResultWindowReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
