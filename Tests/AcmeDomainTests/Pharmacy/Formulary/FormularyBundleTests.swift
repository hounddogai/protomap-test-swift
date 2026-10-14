@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyBundleTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newFormularyBundle("code-695", name: "name-786")
        #expect(item.status == Pharmacy.FormularyBundleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Pharmacy.newFormularyBundle("code-695", name: "name-786")
        try item.moveTo(Pharmacy.FormularyBundleStatus.retired)
        #expect(item.status == Pharmacy.FormularyBundleStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newFormularyBundle("code-695", name: "name-786")
        item.status = Pharmacy.FormularyBundleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularyBundleStatus.created) }
    }
}
