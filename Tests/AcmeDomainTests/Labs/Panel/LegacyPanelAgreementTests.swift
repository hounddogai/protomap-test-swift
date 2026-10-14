@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyPanelAgreementTests {
    @Test func startsInRequested() throws {
        let item = Labs.newLegacyPanelAgreement("code-538", name: "name-793")
        #expect(item.status == Labs.LegacyPanelAgreementStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Labs.newLegacyPanelAgreement("code-538", name: "name-793")
        try item.moveTo(Labs.LegacyPanelAgreementStatus.revoked)
        #expect(item.status == Labs.LegacyPanelAgreementStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newLegacyPanelAgreement("code-538", name: "name-793")
        item.status = Labs.LegacyPanelAgreementStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LegacyPanelAgreementStatus.requested) }
    }
}
