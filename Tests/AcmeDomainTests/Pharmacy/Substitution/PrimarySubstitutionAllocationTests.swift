@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimarySubstitutionAllocationTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newPrimarySubstitutionAllocation("code-980", name: "name-294")
        #expect(item.status == Pharmacy.PrimarySubstitutionAllocationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Pharmacy.newPrimarySubstitutionAllocation("code-980", name: "name-294")
        try item.moveTo(Pharmacy.PrimarySubstitutionAllocationStatus.granted)
        #expect(item.status == Pharmacy.PrimarySubstitutionAllocationStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newPrimarySubstitutionAllocation("code-980", name: "name-294")
        item.status = Pharmacy.PrimarySubstitutionAllocationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PrimarySubstitutionAllocationStatus.requested) }
    }
}
