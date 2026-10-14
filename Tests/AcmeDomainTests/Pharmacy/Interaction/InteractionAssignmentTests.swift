@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionAssignmentTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newInteractionAssignment("code-790", title: "title-445")
        #expect(item.status == Pharmacy.InteractionAssignmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Pharmacy.newInteractionAssignment("code-790", title: "title-445")
        try item.moveTo(Pharmacy.InteractionAssignmentStatus.withdrawn)
        #expect(item.status == Pharmacy.InteractionAssignmentStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newInteractionAssignment("code-790", title: "title-445")
        item.status = Pharmacy.InteractionAssignmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionAssignmentStatus.proposed) }
    }
}
