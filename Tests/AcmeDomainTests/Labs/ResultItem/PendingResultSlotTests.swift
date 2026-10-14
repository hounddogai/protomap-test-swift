@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingResultSlotTests {
    @Test func startsInCreated() throws {
        let item = Labs.newPendingResultSlot("code-723", name: "name-523")
        #expect(item.status == Labs.PendingResultSlotStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newPendingResultSlot("code-723", name: "name-523")
        try item.moveTo(Labs.PendingResultSlotStatus.validated)
        #expect(item.status == Labs.PendingResultSlotStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newPendingResultSlot("code-723", name: "name-523")
        item.status = Labs.PendingResultSlotStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PendingResultSlotStatus.created) }
    }
}
