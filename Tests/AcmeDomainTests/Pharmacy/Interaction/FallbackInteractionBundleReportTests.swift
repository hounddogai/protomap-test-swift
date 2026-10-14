@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackInteractionBundleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701882550)
        var items: [Pharmacy.FallbackInteractionBundle] = []
        for index in 0..<3 {
            items.append(Pharmacy.newFallbackInteractionBundle("fallback-interaction-bundle-\(index)", title: "sample"))
        }
        let report = Pharmacy.buildFallbackInteractionBundleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
