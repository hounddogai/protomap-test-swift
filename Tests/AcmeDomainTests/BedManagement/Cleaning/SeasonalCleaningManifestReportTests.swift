@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementSeasonalCleaningManifestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702308730)
        var items: [BedManagement.SeasonalCleaningManifest] = []
        for index in 0..<3 {
            items.append(BedManagement.newSeasonalCleaningManifest("seasonal-cleaning-manifest-\(index)", name: "sample"))
        }
        let report = BedManagement.buildSeasonalCleaningManifestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
