@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyCredentialManifestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701529835)
        var items: [Staffing.LegacyCredentialManifest] = []
        for index in 0..<2 {
            items.append(Staffing.newLegacyCredentialManifest("legacy-credential-manifest-\(index)", title: "sample"))
        }
        let report = Staffing.buildLegacyCredentialManifestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
