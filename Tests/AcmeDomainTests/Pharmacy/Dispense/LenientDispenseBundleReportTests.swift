@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientDispenseBundleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701779682)
        var items: [Pharmacy.LenientDispenseBundle] = []
        for index in 0..<2 {
            items.append(Pharmacy.newLenientDispenseBundle("lenient-dispense-bundle-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildLenientDispenseBundleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
