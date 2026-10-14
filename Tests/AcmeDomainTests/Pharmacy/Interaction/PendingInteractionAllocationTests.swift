@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingInteractionAllocationTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newPendingInteractionAllocation("code-109", label: "label-365")
        #expect(item.status == Pharmacy.PendingInteractionAllocationStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Pharmacy.newPendingInteractionAllocation("code-109", label: "label-365")
        try item.moveTo(Pharmacy.PendingInteractionAllocationStatus.inProgress)
        #expect(item.status == Pharmacy.PendingInteractionAllocationStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newPendingInteractionAllocation("code-109", label: "label-365")
        item.status = Pharmacy.PendingInteractionAllocationStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PendingInteractionAllocationStatus.planned) }
    }
}
