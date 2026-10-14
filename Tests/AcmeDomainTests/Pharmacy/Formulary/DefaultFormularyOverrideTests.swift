@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultFormularyOverrideTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newDefaultFormularyOverride("code-196", name: "name-891")
        #expect(item.status == Pharmacy.DefaultFormularyOverrideStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Pharmacy.newDefaultFormularyOverride("code-196", name: "name-891")
        try item.moveTo(Pharmacy.DefaultFormularyOverrideStatus.scheduled)
        #expect(item.status == Pharmacy.DefaultFormularyOverrideStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newDefaultFormularyOverride("code-196", name: "name-891")
        item.status = Pharmacy.DefaultFormularyOverrideStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DefaultFormularyOverrideStatus.planned) }
    }
}
