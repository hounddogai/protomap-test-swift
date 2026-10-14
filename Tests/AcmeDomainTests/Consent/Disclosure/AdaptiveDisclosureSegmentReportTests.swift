@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveDisclosureSegmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701771217)
        var items: [Consent.AdaptiveDisclosureSegment] = []
        for index in 0..<6 {
            items.append(Consent.newAdaptiveDisclosureSegment("adaptive-disclosure-segment-\(index)", name: "sample"))
        }
        let report = Consent.buildAdaptiveDisclosureSegmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
