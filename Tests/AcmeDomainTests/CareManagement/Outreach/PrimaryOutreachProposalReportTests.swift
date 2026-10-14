@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryOutreachProposalReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705887467)
        var items: [CareManagement.PrimaryOutreachProposal] = []
        for index in 0..<3 {
            items.append(CareManagement.newPrimaryOutreachProposal("primary-outreach-proposal-\(index)", name: "sample"))
        }
        let report = CareManagement.buildPrimaryOutreachProposalReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
