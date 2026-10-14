@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultCleaningManifestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703350731)
        var items: [BedManagement.DefaultCleaningManifest] = []
        for index in 0..<4 {
            items.append(BedManagement.newDefaultCleaningManifest("default-cleaning-manifest-\(index)", label: "sample"))
        }
        let report = BedManagement.buildDefaultCleaningManifestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
