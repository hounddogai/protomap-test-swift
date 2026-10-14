@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalBedBoardDraftTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newGlobalBedBoardDraft("code-911", label: "label-755")
        #expect(item.status == BedManagement.GlobalBedBoardDraftStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = BedManagement.newGlobalBedBoardDraft("code-911", label: "label-755")
        try item.moveTo(BedManagement.GlobalBedBoardDraftStatus.revoked)
        #expect(item.status == BedManagement.GlobalBedBoardDraftStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newGlobalBedBoardDraft("code-911", label: "label-755")
        item.status = BedManagement.GlobalBedBoardDraftStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.GlobalBedBoardDraftStatus.requested) }
    }
}
