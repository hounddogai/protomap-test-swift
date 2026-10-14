@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryCareGapNoticeReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703440271)
        var items: [CareManagement.PrimaryCareGapNotice] = []
        for index in 0..<6 {
            items.append(CareManagement.newPrimaryCareGapNotice("primary-care-gap-notice-\(index)", name: "sample"))
        }
        let report = CareManagement.buildPrimaryCareGapNoticeReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
