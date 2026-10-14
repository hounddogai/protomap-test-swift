@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardAgreementTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newBedBoardAgreement("code-806", label: "label-583")
        #expect(item.status == BedManagement.BedBoardAgreementStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = BedManagement.newBedBoardAgreement("code-806", label: "label-583")
        try item.moveTo(BedManagement.BedBoardAgreementStatus.done)
        #expect(item.status == BedManagement.BedBoardAgreementStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newBedBoardAgreement("code-806", label: "label-583")
        item.status = BedManagement.BedBoardAgreementStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardAgreementStatus.new) }
    }
}
