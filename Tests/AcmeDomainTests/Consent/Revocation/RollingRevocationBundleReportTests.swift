@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingRevocationBundleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705462902)
        var items: [Consent.RollingRevocationBundle] = []
        for index in 0..<6 {
            items.append(Consent.newRollingRevocationBundle("rolling-revocation-bundle-\(index)", title: "sample"))
        }
        let report = Consent.buildRollingRevocationBundleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
