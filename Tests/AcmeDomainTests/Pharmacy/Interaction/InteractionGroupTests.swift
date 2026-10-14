@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionGroupTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newInteractionGroup("code-116", label: "label-988")
        #expect(item.status == Pharmacy.InteractionGroupStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Pharmacy.newInteractionGroup("code-116", label: "label-988")
        try item.moveTo(Pharmacy.InteractionGroupStatus.resolved)
        #expect(item.status == Pharmacy.InteractionGroupStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newInteractionGroup("code-116", label: "label-988")
        item.status = Pharmacy.InteractionGroupStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionGroupStatus.`open`) }
    }
}
