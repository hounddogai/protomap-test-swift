@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyWindowTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newFormularyWindow("code-153", name: "name-221")
        #expect(item.status == Pharmacy.FormularyWindowStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Pharmacy.newFormularyWindow("code-153", name: "name-221")
        try item.moveTo(Pharmacy.FormularyWindowStatus.granted)
        #expect(item.status == Pharmacy.FormularyWindowStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newFormularyWindow("code-153", name: "name-221")
        item.status = Pharmacy.FormularyWindowStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularyWindowStatus.requested) }
    }
}
