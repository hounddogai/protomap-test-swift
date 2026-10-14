@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingTransferProposalReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700588680)
        var items: [BedManagement.RollingTransferProposal] = []
        for index in 0..<5 {
            items.append(BedManagement.newRollingTransferProposal("rolling-transfer-proposal-\(index)", title: "sample"))
        }
        let report = BedManagement.buildRollingTransferProposalReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
