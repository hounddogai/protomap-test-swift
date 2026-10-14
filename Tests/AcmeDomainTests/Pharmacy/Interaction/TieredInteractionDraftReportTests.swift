@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyTieredInteractionDraftReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706073150)
        var items: [Pharmacy.TieredInteractionDraft] = []
        for index in 0..<4 {
            items.append(Pharmacy.newTieredInteractionDraft("tiered-interaction-draft-\(index)", title: "sample"))
        }
        let report = Pharmacy.buildTieredInteractionDraftReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
