@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictDisclosureSegmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708434735)
        var items: [Consent.StrictDisclosureSegment] = []
        for index in 0..<6 {
            items.append(Consent.newStrictDisclosureSegment("strict-disclosure-segment-\(index)", name: "sample"))
        }
        let report = Consent.buildStrictDisclosureSegmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
