@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsTieredPanelAuditTests {
    @Test func startsInCreated() throws {
        let item = Labs.newTieredPanelAudit("code-681", name: "name-424")
        #expect(item.status == Labs.TieredPanelAuditStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newTieredPanelAudit("code-681", name: "name-424")
        try item.moveTo(Labs.TieredPanelAuditStatus.validated)
        #expect(item.status == Labs.TieredPanelAuditStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newTieredPanelAudit("code-681", name: "name-424")
        item.status = Labs.TieredPanelAuditStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.TieredPanelAuditStatus.created) }
    }
}
