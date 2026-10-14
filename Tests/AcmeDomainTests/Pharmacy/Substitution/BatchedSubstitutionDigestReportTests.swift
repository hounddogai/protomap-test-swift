@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedSubstitutionDigestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701845437)
        var items: [Pharmacy.BatchedSubstitutionDigest] = []
        for index in 0..<5 {
            items.append(Pharmacy.newBatchedSubstitutionDigest("batched-substitution-digest-\(index)", title: "sample"))
        }
        let report = Pharmacy.buildBatchedSubstitutionDigestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
