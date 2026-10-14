@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalInteractionRuleTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newRegionalInteractionRule("code-85", name: "name-191")
        #expect(item.status == Pharmacy.RegionalInteractionRuleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newRegionalInteractionRule("code-85", name: "name-191")
        try item.moveTo(Pharmacy.RegionalInteractionRuleStatus.approved)
        #expect(item.status == Pharmacy.RegionalInteractionRuleStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newRegionalInteractionRule("code-85", name: "name-191")
        item.status = Pharmacy.RegionalInteractionRuleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RegionalInteractionRuleStatus.proposed) }
    }
}
