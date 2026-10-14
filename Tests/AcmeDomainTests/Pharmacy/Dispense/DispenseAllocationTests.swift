@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseAllocationTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newDispenseAllocation("code-526", label: "label-81")
        #expect(item.status == Pharmacy.DispenseAllocationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newDispenseAllocation("code-526", label: "label-81")
        try item.moveTo(Pharmacy.DispenseAllocationStatus.approved)
        #expect(item.status == Pharmacy.DispenseAllocationStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newDispenseAllocation("code-526", label: "label-81")
        item.status = Pharmacy.DispenseAllocationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseAllocationStatus.proposed) }
    }
}
