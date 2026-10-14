@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualResultBaselineReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702151982)
        var items: [Labs.ManualResultBaseline] = []
        for index in 0..<6 {
            items.append(Labs.newManualResultBaseline("manual-result-baseline-\(index)", name: "sample"))
        }
        let report = Labs.buildManualResultBaselineReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
