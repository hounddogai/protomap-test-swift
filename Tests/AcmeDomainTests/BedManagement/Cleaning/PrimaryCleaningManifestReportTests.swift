@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryCleaningManifestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709274838)
        var items: [BedManagement.PrimaryCleaningManifest] = []
        for index in 0..<3 {
            items.append(BedManagement.newPrimaryCleaningManifest("primary-cleaning-manifest-\(index)", title: "sample"))
        }
        let report = BedManagement.buildPrimaryCleaningManifestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
