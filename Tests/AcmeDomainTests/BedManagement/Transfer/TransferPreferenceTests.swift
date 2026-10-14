@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferPreferenceTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newTransferPreference("code-681", title: "title-416")
        #expect(item.status == BedManagement.TransferPreferenceStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = BedManagement.newTransferPreference("code-681", title: "title-416")
        try item.moveTo(BedManagement.TransferPreferenceStatus.inReview)
        #expect(item.status == BedManagement.TransferPreferenceStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newTransferPreference("code-681", title: "title-416")
        item.status = BedManagement.TransferPreferenceStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferPreferenceStatus.`open`) }
    }
}
