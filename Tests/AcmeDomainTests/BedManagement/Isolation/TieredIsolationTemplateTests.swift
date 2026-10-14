@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredIsolationTemplateTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newTieredIsolationTemplate("code-203", label: "label-114")
        #expect(item.status == BedManagement.TieredIsolationTemplateStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newTieredIsolationTemplate("code-203", label: "label-114")
        try item.moveTo(BedManagement.TieredIsolationTemplateStatus.approved)
        #expect(item.status == BedManagement.TieredIsolationTemplateStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newTieredIsolationTemplate("code-203", label: "label-114")
        item.status = BedManagement.TieredIsolationTemplateStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TieredIsolationTemplateStatus.proposed) }
    }
}
