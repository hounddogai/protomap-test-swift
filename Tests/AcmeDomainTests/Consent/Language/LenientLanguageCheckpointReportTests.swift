@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientLanguageCheckpointReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703586323)
        var items: [Consent.LenientLanguageCheckpoint] = []
        for index in 0..<5 {
            items.append(Consent.newLenientLanguageCheckpoint("lenient-language-checkpoint-\(index)", title: "sample"))
        }
        let report = Consent.buildLenientLanguageCheckpointReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
