@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryRoundingProfileReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704206720)
        var items: [ClinicalOps.PrimaryRoundingProfile] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newPrimaryRoundingProfile("primary-rounding-profile-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildPrimaryRoundingProfileReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
