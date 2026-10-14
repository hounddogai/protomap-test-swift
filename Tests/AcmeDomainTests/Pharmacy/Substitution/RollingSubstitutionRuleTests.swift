@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingSubstitutionRuleTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newRollingSubstitutionRule("code-144", name: "name-1")
        #expect(item.status == Pharmacy.RollingSubstitutionRuleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newRollingSubstitutionRule("code-144", name: "name-1")
        try item.moveTo(Pharmacy.RollingSubstitutionRuleStatus.approved)
        #expect(item.status == Pharmacy.RollingSubstitutionRuleStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newRollingSubstitutionRule("code-144", name: "name-1")
        item.status = Pharmacy.RollingSubstitutionRuleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RollingSubstitutionRuleStatus.proposed) }
    }
}
