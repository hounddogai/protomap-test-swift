@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredRiskScoreEntryTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newTieredRiskScoreEntry("code-490", name: "name-618")
        #expect(item.status == CareManagement.TieredRiskScoreEntryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = CareManagement.newTieredRiskScoreEntry("code-490", name: "name-618")
        try item.moveTo(CareManagement.TieredRiskScoreEntryStatus.validated)
        #expect(item.status == CareManagement.TieredRiskScoreEntryStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newTieredRiskScoreEntry("code-490", name: "name-618")
        item.status = CareManagement.TieredRiskScoreEntryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.TieredRiskScoreEntryStatus.created) }
    }
}
