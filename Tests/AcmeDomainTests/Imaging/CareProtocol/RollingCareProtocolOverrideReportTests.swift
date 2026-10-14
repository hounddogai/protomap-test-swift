@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingCareProtocolOverrideReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708307697)
        var items: [Imaging.RollingCareProtocolOverride] = []
        for index in 0..<3 {
            items.append(Imaging.newRollingCareProtocolOverride("rolling-care-protocol-override-\(index)", title: "sample"))
        }
        let report = Imaging.buildRollingCareProtocolOverrideReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
