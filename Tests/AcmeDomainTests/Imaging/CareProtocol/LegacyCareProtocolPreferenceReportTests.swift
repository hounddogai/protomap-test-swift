@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyCareProtocolPreferenceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702600455)
        var items: [Imaging.LegacyCareProtocolPreference] = []
        for index in 0..<2 {
            items.append(Imaging.newLegacyCareProtocolPreference("legacy-care-protocol-preference-\(index)", title: "sample"))
        }
        let report = Imaging.buildLegacyCareProtocolPreferenceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
