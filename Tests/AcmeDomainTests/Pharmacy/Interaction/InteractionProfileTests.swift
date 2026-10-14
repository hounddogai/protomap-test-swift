@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionProfileTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newInteractionProfile("code-920", name: "name-587")
        #expect(item.status == Pharmacy.InteractionProfileStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Pharmacy.newInteractionProfile("code-920", name: "name-587")
        try item.moveTo(Pharmacy.InteractionProfileStatus.published)
        #expect(item.status == Pharmacy.InteractionProfileStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newInteractionProfile("code-920", name: "name-587")
        item.status = Pharmacy.InteractionProfileStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionProfileStatus.created) }
    }
}
