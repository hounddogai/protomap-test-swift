@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionRecordTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newInteractionRecord("code-950", name: "name-231")
        #expect(item.status == Pharmacy.InteractionRecordStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Pharmacy.newInteractionRecord("code-950", name: "name-231")
        try item.moveTo(Pharmacy.InteractionRecordStatus.queued)
        #expect(item.status == Pharmacy.InteractionRecordStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newInteractionRecord("code-950", name: "name-231")
        item.status = Pharmacy.InteractionRecordStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionRecordStatus.new) }
    }
}
