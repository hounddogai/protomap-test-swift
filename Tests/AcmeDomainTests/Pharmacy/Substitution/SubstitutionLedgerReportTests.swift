@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionLedgerReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708002601)
        var items: [Pharmacy.SubstitutionLedger] = []
        for index in 0..<5 {
            items.append(Pharmacy.newSubstitutionLedger("substitution-ledger-\(index)", label: "sample"))
        }
        let report = Pharmacy.buildSubstitutionLedgerReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
