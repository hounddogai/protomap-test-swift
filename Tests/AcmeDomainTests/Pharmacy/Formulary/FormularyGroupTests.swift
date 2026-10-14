@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyGroupTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newFormularyGroup("code-283", name: "name-803")
        #expect(item.status == Pharmacy.FormularyGroupStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Pharmacy.newFormularyGroup("code-283", name: "name-803")
        try item.moveTo(Pharmacy.FormularyGroupStatus.published)
        #expect(item.status == Pharmacy.FormularyGroupStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newFormularyGroup("code-283", name: "name-803")
        item.status = Pharmacy.FormularyGroupStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularyGroupStatus.created) }
    }
}
