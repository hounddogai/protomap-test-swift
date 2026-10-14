@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingConsentFormWindowReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701556768)
        var items: [Consent.RollingConsentFormWindow] = []
        for index in 0..<5 {
            items.append(Consent.newRollingConsentFormWindow("rolling-consent-form-window-\(index)", title: "sample"))
        }
        let report = Consent.buildRollingConsentFormWindowReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
