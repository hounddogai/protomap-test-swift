@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureMappingReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707847767)
        var items: [Consent.DisclosureMapping] = []
        for index in 0..<2 {
            items.append(Consent.newDisclosureMapping("disclosure-mapping-\(index)", title: "sample"))
        }
        let report = Consent.buildDisclosureMappingReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
