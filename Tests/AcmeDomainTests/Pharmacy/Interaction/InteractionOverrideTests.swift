@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionOverrideTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newInteractionOverride("code-539", title: "title-264")
        #expect(item.status == Pharmacy.InteractionOverrideStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Pharmacy.newInteractionOverride("code-539", title: "title-264")
        try item.moveTo(Pharmacy.InteractionOverrideStatus.reopened)
        #expect(item.status == Pharmacy.InteractionOverrideStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newInteractionOverride("code-539", title: "title-264")
        item.status = Pharmacy.InteractionOverrideStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionOverrideStatus.`open`) }
    }
}
