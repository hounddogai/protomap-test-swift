@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionBatchTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newInteractionBatch("code-615", name: "name-662")
        #expect(item.status == Pharmacy.InteractionBatchStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Pharmacy.newInteractionBatch("code-615", name: "name-662")
        try item.moveTo(Pharmacy.InteractionBatchStatus.reopened)
        #expect(item.status == Pharmacy.InteractionBatchStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newInteractionBatch("code-615", name: "name-662")
        item.status = Pharmacy.InteractionBatchStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionBatchStatus.`open`) }
    }
}
