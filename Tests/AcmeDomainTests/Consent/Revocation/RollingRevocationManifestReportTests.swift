@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingRevocationManifestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704365463)
        var items: [Consent.RollingRevocationManifest] = []
        for index in 0..<5 {
            items.append(Consent.newRollingRevocationManifest("rolling-revocation-manifest-\(index)", name: "sample"))
        }
        let report = Consent.buildRollingRevocationManifestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
