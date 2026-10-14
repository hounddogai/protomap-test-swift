@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionRuleTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newSubstitutionRule("code-618", title: "title-969")
        #expect(item.status == Pharmacy.SubstitutionRuleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Pharmacy.newSubstitutionRule("code-618", title: "title-969")
        try item.moveTo(Pharmacy.SubstitutionRuleStatus.validated)
        #expect(item.status == Pharmacy.SubstitutionRuleStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newSubstitutionRule("code-618", title: "title-969")
        item.status = Pharmacy.SubstitutionRuleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionRuleStatus.created) }
    }
}
