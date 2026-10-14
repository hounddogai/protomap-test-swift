@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCensusRuleTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newScheduledCensusRule("code-924", title: "title-130")
        #expect(item.status == BedManagement.ScheduledCensusRuleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = BedManagement.newScheduledCensusRule("code-924", title: "title-130")
        try item.moveTo(BedManagement.ScheduledCensusRuleStatus.resolved)
        #expect(item.status == BedManagement.ScheduledCensusRuleStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newScheduledCensusRule("code-924", title: "title-130")
        item.status = BedManagement.ScheduledCensusRuleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ScheduledCensusRuleStatus.`open`) }
    }
}
