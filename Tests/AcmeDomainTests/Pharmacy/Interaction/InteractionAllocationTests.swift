@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionAllocationTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newInteractionAllocation("code-442", name: "name-172")
        #expect(item.status == Pharmacy.InteractionAllocationStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Pharmacy.newInteractionAllocation("code-442", name: "name-172")
        try item.moveTo(Pharmacy.InteractionAllocationStatus.suspended)
        #expect(item.status == Pharmacy.InteractionAllocationStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newInteractionAllocation("code-442", name: "name-172")
        item.status = Pharmacy.InteractionAllocationStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionAllocationStatus.draft) }
    }
}
