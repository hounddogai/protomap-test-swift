@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormPlanReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708066241)
        var items: [Consent.ConsentFormPlan] = []
        for index in 0..<3 {
            items.append(Consent.newConsentFormPlan("consent-form-plan-\(index)", name: "sample"))
        }
        let report = Consent.buildConsentFormPlanReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
