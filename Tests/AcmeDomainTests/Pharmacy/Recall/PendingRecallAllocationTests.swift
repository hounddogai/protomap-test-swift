@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingRecallAllocationTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newPendingRecallAllocation("code-741", name: "name-308")
        #expect(item.status == Pharmacy.PendingRecallAllocationStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Pharmacy.newPendingRecallAllocation("code-741", name: "name-308")
        try item.moveTo(Pharmacy.PendingRecallAllocationStatus.active)
        #expect(item.status == Pharmacy.PendingRecallAllocationStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newPendingRecallAllocation("code-741", name: "name-308")
        item.status = Pharmacy.PendingRecallAllocationStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PendingRecallAllocationStatus.draft) }
    }
}
