@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryDischargePlanProposalReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708389906)
        var items: [BedManagement.PrimaryDischargePlanProposal] = []
        for index in 0..<4 {
            items.append(BedManagement.newPrimaryDischargePlanProposal("primary-discharge-plan-proposal-\(index)", name: "sample"))
        }
        let report = BedManagement.buildPrimaryDischargePlanProposalReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
