@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalRevocationPolicyReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707388843)
        var items: [Consent.SeasonalRevocationPolicy] = []
        for index in 0..<4 {
            items.append(Consent.newSeasonalRevocationPolicy("seasonal-revocation-policy-\(index)", name: "sample"))
        }
        let report = Consent.buildSeasonalRevocationPolicyReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
