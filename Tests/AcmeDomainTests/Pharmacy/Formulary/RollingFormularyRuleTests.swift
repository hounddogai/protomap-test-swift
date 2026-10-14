@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingFormularyRuleTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newRollingFormularyRule("code-548", name: "name-593")
        #expect(item.status == Pharmacy.RollingFormularyRuleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Pharmacy.newRollingFormularyRule("code-548", name: "name-593")
        try item.moveTo(Pharmacy.RollingFormularyRuleStatus.published)
        #expect(item.status == Pharmacy.RollingFormularyRuleStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newRollingFormularyRule("code-548", name: "name-593")
        item.status = Pharmacy.RollingFormularyRuleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RollingFormularyRuleStatus.created) }
    }
}
