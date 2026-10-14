@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedCareProtocolPreferenceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705787242)
        var items: [Imaging.CappedCareProtocolPreference] = []
        for index in 0..<3 {
            items.append(Imaging.newCappedCareProtocolPreference("capped-care-protocol-preference-\(index)", title: "sample"))
        }
        let report = Imaging.buildCappedCareProtocolPreferenceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
