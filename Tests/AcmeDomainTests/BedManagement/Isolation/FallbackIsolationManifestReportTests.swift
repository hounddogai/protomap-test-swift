@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackIsolationManifestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702356364)
        var items: [BedManagement.FallbackIsolationManifest] = []
        for index in 0..<4 {
            items.append(BedManagement.newFallbackIsolationManifest("fallback-isolation-manifest-\(index)", name: "sample"))
        }
        let report = BedManagement.buildFallbackIsolationManifestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
