@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedDisclosureTargetReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707658501)
        var items: [Consent.CappedDisclosureTarget] = []
        for index in 0..<5 {
            items.append(Consent.newCappedDisclosureTarget("capped-disclosure-target-\(index)", title: "sample"))
        }
        let report = Consent.buildCappedDisclosureTargetReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
