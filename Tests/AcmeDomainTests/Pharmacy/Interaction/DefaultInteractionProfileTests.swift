@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultInteractionProfileTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newDefaultInteractionProfile("code-210", name: "name-598")
        #expect(item.status == Pharmacy.DefaultInteractionProfileStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Pharmacy.newDefaultInteractionProfile("code-210", name: "name-598")
        try item.moveTo(Pharmacy.DefaultInteractionProfileStatus.retired)
        #expect(item.status == Pharmacy.DefaultInteractionProfileStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newDefaultInteractionProfile("code-210", name: "name-598")
        item.status = Pharmacy.DefaultInteractionProfileStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DefaultInteractionProfileStatus.created) }
    }
}
