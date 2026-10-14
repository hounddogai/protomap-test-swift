@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedDispenseCheckpointTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newCappedDispenseCheckpoint("code-568", title: "title-914")
        #expect(item.status == Pharmacy.CappedDispenseCheckpointStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Pharmacy.newCappedDispenseCheckpoint("code-568", title: "title-914")
        try item.moveTo(Pharmacy.CappedDispenseCheckpointStatus.published)
        #expect(item.status == Pharmacy.CappedDispenseCheckpointStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newCappedDispenseCheckpoint("code-568", title: "title-914")
        item.status = Pharmacy.CappedDispenseCheckpointStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.CappedDispenseCheckpointStatus.created) }
    }
}
