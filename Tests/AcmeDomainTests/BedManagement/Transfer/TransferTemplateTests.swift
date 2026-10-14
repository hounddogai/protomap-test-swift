@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferTemplateTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newTransferTemplate("code-353", title: "title-762")
        #expect(item.status == BedManagement.TransferTemplateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = BedManagement.newTransferTemplate("code-353", title: "title-762")
        try item.moveTo(BedManagement.TransferTemplateStatus.reopened)
        #expect(item.status == BedManagement.TransferTemplateStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newTransferTemplate("code-353", title: "title-762")
        item.status = BedManagement.TransferTemplateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferTemplateStatus.`open`) }
    }
}
