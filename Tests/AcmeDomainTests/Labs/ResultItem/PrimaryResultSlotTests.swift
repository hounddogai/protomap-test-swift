@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryResultSlotTests {
    @Test func startsInProposed() throws {
        let item = Labs.newPrimaryResultSlot("code-566", title: "title-262")
        #expect(item.status == Labs.PrimaryResultSlotStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Labs.newPrimaryResultSlot("code-566", title: "title-262")
        try item.moveTo(Labs.PrimaryResultSlotStatus.rejected)
        #expect(item.status == Labs.PrimaryResultSlotStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newPrimaryResultSlot("code-566", title: "title-262")
        item.status = Labs.PrimaryResultSlotStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PrimaryResultSlotStatus.proposed) }
    }
}
