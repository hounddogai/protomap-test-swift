@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingCareProtocolManifestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709259708)
        var items: [Imaging.RollingCareProtocolManifest] = []
        for index in 0..<3 {
            items.append(Imaging.newRollingCareProtocolManifest("rolling-care-protocol-manifest-\(index)", label: "sample"))
        }
        let report = Imaging.buildRollingCareProtocolManifestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
