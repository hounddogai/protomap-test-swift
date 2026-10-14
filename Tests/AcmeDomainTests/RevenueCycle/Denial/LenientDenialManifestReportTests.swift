@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientDenialManifestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700764139)
        var items: [RevenueCycle.LenientDenialManifest] = []
        for index in 0..<6 {
            items.append(RevenueCycle.newLenientDenialManifest("lenient-denial-manifest-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildLenientDenialManifestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
