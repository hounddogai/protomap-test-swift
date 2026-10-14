@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyRuleTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newFormularyRule("code-394", name: "name-3")
        #expect(item.status == Pharmacy.FormularyRuleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Pharmacy.newFormularyRule("code-394", name: "name-3")
        try item.moveTo(Pharmacy.FormularyRuleStatus.active)
        #expect(item.status == Pharmacy.FormularyRuleStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newFormularyRule("code-394", name: "name-3")
        item.status = Pharmacy.FormularyRuleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularyRuleStatus.draft) }
    }
}
