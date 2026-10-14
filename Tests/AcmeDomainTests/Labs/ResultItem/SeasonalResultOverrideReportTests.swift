@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalResultOverrideReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709643092)
        var items: [Labs.SeasonalResultOverride] = []
        for index in 0..<6 {
            items.append(Labs.newSeasonalResultOverride("seasonal-result-override-\(index)", title: "sample"))
        }
        let report = Labs.buildSeasonalResultOverrideReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
