@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusRuleTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newCensusRule("code-6", name: "name-435")
        #expect(item.status == BedManagement.CensusRuleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newCensusRule("code-6", name: "name-435")
        try item.moveTo(BedManagement.CensusRuleStatus.granted)
        #expect(item.status == BedManagement.CensusRuleStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newCensusRule("code-6", name: "name-435")
        item.status = BedManagement.CensusRuleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusRuleStatus.requested) }
    }
}
