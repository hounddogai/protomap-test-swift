@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyAuthorizationAgreementReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700846060)
        var items: [RevenueCycle.LegacyAuthorizationAgreement] = []
        for index in 0..<3 {
            items.append(RevenueCycle.newLegacyAuthorizationAgreement("legacy-authorization-agreement-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildLegacyAuthorizationAgreementReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
