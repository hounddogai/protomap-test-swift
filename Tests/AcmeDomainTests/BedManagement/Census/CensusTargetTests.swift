@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusTargetTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newCensusTarget("code-610", label: "label-975")
        #expect(item.status == BedManagement.CensusTargetStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = BedManagement.newCensusTarget("code-610", label: "label-975")
        try item.moveTo(BedManagement.CensusTargetStatus.inReview)
        #expect(item.status == BedManagement.CensusTargetStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newCensusTarget("code-610", label: "label-975")
        item.status = BedManagement.CensusTargetStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusTargetStatus.`open`) }
    }
}
