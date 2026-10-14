@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalSubstitutionTargetTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newGlobalSubstitutionTarget("code-617", name: "name-203")
        #expect(item.status == Pharmacy.GlobalSubstitutionTargetStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Pharmacy.newGlobalSubstitutionTarget("code-617", name: "name-203")
        try item.moveTo(Pharmacy.GlobalSubstitutionTargetStatus.revoked)
        #expect(item.status == Pharmacy.GlobalSubstitutionTargetStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newGlobalSubstitutionTarget("code-617", name: "name-203")
        item.status = Pharmacy.GlobalSubstitutionTargetStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.GlobalSubstitutionTargetStatus.requested) }
    }
}
