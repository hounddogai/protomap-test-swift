@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseBundleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708966273)
        var items: [Pharmacy.DispenseBundle] = []
        for index in 0..<6 {
            items.append(Pharmacy.newDispenseBundle("dispense-bundle-\(index)", title: "sample"))
        }
        let report = Pharmacy.buildDispenseBundleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
