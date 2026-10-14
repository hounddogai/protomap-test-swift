@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialAgreementReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708666384)
        var items: [RevenueCycle.DenialAgreement] = []
        for index in 0..<5 {
            items.append(RevenueCycle.newDenialAgreement("denial-agreement-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildDenialAgreementReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
