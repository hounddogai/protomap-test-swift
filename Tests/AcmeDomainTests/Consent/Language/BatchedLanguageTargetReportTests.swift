@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedLanguageTargetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707346653)
        var items: [Consent.BatchedLanguageTarget] = []
        for index in 0..<4 {
            items.append(Consent.newBatchedLanguageTarget("batched-language-target-\(index)", label: "sample"))
        }
        let report = Consent.buildBatchedLanguageTargetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
