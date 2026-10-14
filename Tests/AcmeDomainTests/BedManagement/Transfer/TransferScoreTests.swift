@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferScoreTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newTransferScore("code-586", label: "label-359")
        #expect(item.status == BedManagement.TransferScoreStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = BedManagement.newTransferScore("code-586", label: "label-359")
        try item.moveTo(BedManagement.TransferScoreStatus.validated)
        #expect(item.status == BedManagement.TransferScoreStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newTransferScore("code-586", label: "label-359")
        item.status = BedManagement.TransferScoreStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferScoreStatus.created) }
    }
}
