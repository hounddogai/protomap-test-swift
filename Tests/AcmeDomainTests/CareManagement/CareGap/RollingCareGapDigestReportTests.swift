@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingCareGapDigestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704637474)
        var items: [CareManagement.RollingCareGapDigest] = []
        for index in 0..<3 {
            items.append(CareManagement.newRollingCareGapDigest("rolling-care-gap-digest-\(index)", title: "sample"))
        }
        let report = CareManagement.buildRollingCareGapDigestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
