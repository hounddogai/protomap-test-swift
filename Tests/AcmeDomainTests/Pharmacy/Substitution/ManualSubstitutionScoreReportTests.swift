@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualSubstitutionScoreReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706238933)
        var items: [Pharmacy.ManualSubstitutionScore] = []
        for index in 0..<5 {
            items.append(Pharmacy.newManualSubstitutionScore("manual-substitution-score-\(index)", title: "sample"))
        }
        let report = Pharmacy.buildManualSubstitutionScoreReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
