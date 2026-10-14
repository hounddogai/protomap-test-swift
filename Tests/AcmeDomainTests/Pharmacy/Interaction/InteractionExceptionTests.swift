@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionExceptionTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newInteractionException("code-853", label: "label-572")
        #expect(item.status == Pharmacy.InteractionExceptionStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newInteractionException("code-853", label: "label-572")
        try item.moveTo(Pharmacy.InteractionExceptionStatus.approved)
        #expect(item.status == Pharmacy.InteractionExceptionStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newInteractionException("code-853", label: "label-572")
        item.status = Pharmacy.InteractionExceptionStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionExceptionStatus.proposed) }
    }
}
