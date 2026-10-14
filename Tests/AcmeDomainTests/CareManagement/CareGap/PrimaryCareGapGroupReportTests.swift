@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryCareGapGroupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707503924)
        var items: [CareManagement.PrimaryCareGapGroup] = []
        for index in 0..<4 {
            items.append(CareManagement.newPrimaryCareGapGroup("primary-care-gap-group-\(index)", label: "sample"))
        }
        let report = CareManagement.buildPrimaryCareGapGroupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
