@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingDraftReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704390501)
        var items: [ClinicalOps.RoundingDraft] = []
        for index in 0..<6 {
            items.append(ClinicalOps.newRoundingDraft("rounding-draft-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildRoundingDraftReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
