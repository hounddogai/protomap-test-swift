@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalTransferTemplateTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newGlobalTransferTemplate("code-180", name: "name-19")
        #expect(item.status == BedManagement.GlobalTransferTemplateStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = BedManagement.newGlobalTransferTemplate("code-180", name: "name-19")
        try item.moveTo(BedManagement.GlobalTransferTemplateStatus.active)
        #expect(item.status == BedManagement.GlobalTransferTemplateStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newGlobalTransferTemplate("code-180", name: "name-19")
        item.status = BedManagement.GlobalTransferTemplateStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.GlobalTransferTemplateStatus.draft) }
    }
}
