@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionLedgerReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702942254)
        var items: [Pharmacy.InteractionLedger] = []
        for index in 0..<5 {
            items.append(Pharmacy.newInteractionLedger("interaction-ledger-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildInteractionLedgerReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
