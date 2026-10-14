@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeProposalReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706988704)
        var items: [Staffing.OvertimeProposal] = []
        for index in 0..<4 {
            items.append(Staffing.newOvertimeProposal("overtime-proposal-\(index)", name: "sample"))
        }
        let report = Staffing.buildOvertimeProposalReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
