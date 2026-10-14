@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionMappingTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newInteractionMapping("code-932", title: "title-610")
        #expect(item.status == Pharmacy.InteractionMappingStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newInteractionMapping("code-932", title: "title-610")
        try item.moveTo(Pharmacy.InteractionMappingStatus.approved)
        #expect(item.status == Pharmacy.InteractionMappingStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newInteractionMapping("code-932", title: "title-610")
        item.status = Pharmacy.InteractionMappingStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionMappingStatus.proposed) }
    }
}
