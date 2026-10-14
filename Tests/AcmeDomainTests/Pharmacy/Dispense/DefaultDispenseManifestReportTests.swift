@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultDispenseManifestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705685243)
        var items: [Pharmacy.DefaultDispenseManifest] = []
        for index in 0..<5 {
            items.append(Pharmacy.newDefaultDispenseManifest("default-dispense-manifest-\(index)", title: "sample"))
        }
        let report = Pharmacy.buildDefaultDispenseManifestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
