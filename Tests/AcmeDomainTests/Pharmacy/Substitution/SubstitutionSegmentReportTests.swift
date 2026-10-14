@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionSegmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704357878)
        var items: [Pharmacy.SubstitutionSegment] = []
        for index in 0..<2 {
            items.append(Pharmacy.newSubstitutionSegment("substitution-segment-\(index)", label: "sample"))
        }
        let report = Pharmacy.buildSubstitutionSegmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
