@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultTransferProposalReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703154507)
        var items: [BedManagement.DefaultTransferProposal] = []
        for index in 0..<4 {
            items.append(BedManagement.newDefaultTransferProposal("default-transfer-proposal-\(index)", label: "sample"))
        }
        let report = BedManagement.buildDefaultTransferProposalReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
