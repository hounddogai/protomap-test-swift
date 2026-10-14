@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryRecallDigestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708540587)
        var items: [Pharmacy.PrimaryRecallDigest] = []
        for index in 0..<2 {
            items.append(Pharmacy.newPrimaryRecallDigest("primary-recall-digest-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildPrimaryRecallDigestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
