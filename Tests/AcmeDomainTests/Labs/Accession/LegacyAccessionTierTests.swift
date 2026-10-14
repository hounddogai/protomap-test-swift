@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyAccessionTierTests {
    @Test func startsInProposed() throws {
        let item = Labs.newLegacyAccessionTier("code-61", label: "label-671")
        #expect(item.status == Labs.LegacyAccessionTierStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newLegacyAccessionTier("code-61", label: "label-671")
        try item.moveTo(Labs.LegacyAccessionTierStatus.rejected)
        #expect(item.status == Labs.LegacyAccessionTierStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newLegacyAccessionTier("code-61", label: "label-671")
        item.status = Labs.LegacyAccessionTierStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LegacyAccessionTierStatus.proposed) }
    }
}
