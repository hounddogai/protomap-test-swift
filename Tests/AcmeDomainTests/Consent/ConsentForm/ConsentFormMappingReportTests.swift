@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormMappingReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703562088)
        var items: [Consent.ConsentFormMapping] = []
        for index in 0..<2 {
            items.append(Consent.newConsentFormMapping("consent-form-mapping-\(index)", label: "sample"))
        }
        let report = Consent.buildConsentFormMappingReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
