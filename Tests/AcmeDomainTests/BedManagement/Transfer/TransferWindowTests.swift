@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferWindowTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newTransferWindow("code-505", title: "title-429")
        #expect(item.status == BedManagement.TransferWindowStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = BedManagement.newTransferWindow("code-505", title: "title-429")
        try item.moveTo(BedManagement.TransferWindowStatus.validated)
        #expect(item.status == BedManagement.TransferWindowStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newTransferWindow("code-505", title: "title-429")
        item.status = BedManagement.TransferWindowStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferWindowStatus.created) }
    }
}
