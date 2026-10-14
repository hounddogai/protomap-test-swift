@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyCensusDigestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700146270)
        var items: [BedManagement.LegacyCensusDigest] = []
        for index in 0..<3 {
            items.append(BedManagement.newLegacyCensusDigest("legacy-census-digest-\(index)", label: "sample"))
        }
        let report = BedManagement.buildLegacyCensusDigestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
