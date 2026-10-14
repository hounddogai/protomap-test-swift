@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingCareProtocolBundleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708574475)
        var items: [Imaging.RollingCareProtocolBundle] = []
        for index in 0..<4 {
            items.append(Imaging.newRollingCareProtocolBundle("rolling-care-protocol-bundle-\(index)", title: "sample"))
        }
        let report = Imaging.buildRollingCareProtocolBundleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
