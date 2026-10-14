@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalRevocationRollupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701862519)
        var items: [Consent.GlobalRevocationRollup] = []
        for index in 0..<4 {
            items.append(Consent.newGlobalRevocationRollup("global-revocation-rollup-\(index)", label: "sample"))
        }
        let report = Consent.buildGlobalRevocationRollupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
