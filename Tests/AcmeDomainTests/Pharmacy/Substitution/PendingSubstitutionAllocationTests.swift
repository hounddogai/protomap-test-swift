@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingSubstitutionAllocationTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newPendingSubstitutionAllocation("code-552", title: "title-461")
        #expect(item.status == Pharmacy.PendingSubstitutionAllocationStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Pharmacy.newPendingSubstitutionAllocation("code-552", title: "title-461")
        try item.moveTo(Pharmacy.PendingSubstitutionAllocationStatus.pending)
        #expect(item.status == Pharmacy.PendingSubstitutionAllocationStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newPendingSubstitutionAllocation("code-552", title: "title-461")
        item.status = Pharmacy.PendingSubstitutionAllocationStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PendingSubstitutionAllocationStatus.draft) }
    }
}
