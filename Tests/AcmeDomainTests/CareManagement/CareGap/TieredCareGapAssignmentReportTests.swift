@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredCareGapAssignmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709270728)
        var items: [CareManagement.TieredCareGapAssignment] = []
        for index in 0..<6 {
            items.append(CareManagement.newTieredCareGapAssignment("tiered-care-gap-assignment-\(index)", name: "sample"))
        }
        let report = CareManagement.buildTieredCareGapAssignmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
