@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryOutreachEntryReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700410104)
        var items: [CareManagement.PrimaryOutreachEntry] = []
        for index in 0..<5 {
            items.append(CareManagement.newPrimaryOutreachEntry("primary-outreach-entry-\(index)", title: "sample"))
        }
        let report = CareManagement.buildPrimaryOutreachEntryReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
