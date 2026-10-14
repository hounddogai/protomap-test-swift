@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalLanguageCheckpointReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701946514)
        var items: [Consent.SeasonalLanguageCheckpoint] = []
        for index in 0..<6 {
            items.append(Consent.newSeasonalLanguageCheckpoint("seasonal-language-checkpoint-\(index)", title: "sample"))
        }
        let report = Consent.buildSeasonalLanguageCheckpointReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
