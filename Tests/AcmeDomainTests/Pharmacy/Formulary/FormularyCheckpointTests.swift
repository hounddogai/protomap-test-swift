@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyCheckpointTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newFormularyCheckpoint("code-542", name: "name-405")
        #expect(item.status == Pharmacy.FormularyCheckpointStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Pharmacy.newFormularyCheckpoint("code-542", name: "name-405")
        try item.moveTo(Pharmacy.FormularyCheckpointStatus.inReview)
        #expect(item.status == Pharmacy.FormularyCheckpointStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newFormularyCheckpoint("code-542", name: "name-405")
        item.status = Pharmacy.FormularyCheckpointStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularyCheckpointStatus.`open`) }
    }
}
