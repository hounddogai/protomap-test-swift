@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionPolicyTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newSubstitutionPolicy("code-952", title: "title-645")
        #expect(item.status == Pharmacy.SubstitutionPolicyStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newSubstitutionPolicy("code-952", title: "title-645")
        try item.moveTo(Pharmacy.SubstitutionPolicyStatus.approved)
        #expect(item.status == Pharmacy.SubstitutionPolicyStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newSubstitutionPolicy("code-952", title: "title-645")
        item.status = Pharmacy.SubstitutionPolicyStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionPolicyStatus.proposed) }
    }
}
